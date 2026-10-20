#!/bin/bash

# API测试脚本
# 测试所有后端API端点并生成报告

BASE_URL="http://localhost:3000"
REPORT_DIR="/Volumes/Mac Data/Documents/StudioProjects/japanese-learning/test-reports"
REPORT_FILE="$REPORT_DIR/backend-api-test-$(date +%Y%m%d).md"

# 创建测试报告目录
mkdir -p "$REPORT_DIR"

# 初始化测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试结果数组
declare -a TEST_RESULTS

# 测试函数
test_api() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    local auth_header=$5
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo "Testing: $method $endpoint"
    
    # 构建curl命令
    if [ -n "$data" ]; then
        cmd="curl -s -w '\n%{http_code}\n%{time_total}' -X $method '$BASE_URL$endpoint' -H 'Content-Type: application/json' -d '$data'"
    else
        cmd="curl -s -w '\n%{http_code}\n%{time_total}' -X $method '$BASE_URL$endpoint'"
    fi
    
    # 添加认证头
    if [ -n "$auth_header" ]; then
        cmd="$cmd -H '$auth_header'"
    fi
    
    # 执行请求
    response=$(eval $cmd)
    
    # 解析响应
    http_code=$(echo "$response" | tail -n 2 | head -n 1)
    response_time=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d' | sed '$d')
    
    # 判断测试结果
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        status="✅ 通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        status="❌ 失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # 存储结果
    TEST_RESULTS+=("$description|$endpoint|$http_code|$response_time|$status|$body")
    
    echo "  状态码: $http_code | 响应时间: ${response_time}s | 状态: $status"
}

echo "========================================="
echo "开始API测试..."
echo "========================================="

# 1. 测试词汇API
echo ""
echo "1. 测试词汇API..."
test_api "GET" "/vocabulary" "获取词汇列表"
test_api "GET" "/vocabulary/1" "获取单个词汇(id=1)"

# 创建测试词汇数据
vocab_data='{"word":"テスト","reading":"てすと","meaning":"测试","example":"これはテストです。","level":1,"tags":["test"]}'
test_api "POST" "/vocabulary" "创建词汇" "$vocab_data"

# 2. 测试语法API
echo ""
echo "2. 测试语法API..."
test_api "GET" "/grammar" "获取语法列表"
test_api "GET" "/grammar/1" "获取单个语法(id=1)"

# 创建测试语法数据
grammar_data='{"title":"は+が","structure":"N + は/が + V","meaning":"主题标记","example":"私は学生です。","level":1}'
test_api "POST" "/grammar" "创建语法" "$grammar_data"

# 3. 测试问题和练习API
echo ""
echo "3. 测试问题和练习API..."
test_api "GET" "/vocabulary/1/questions" "获取词汇问题(id=1)"
test_api "GET" "/grammar/1/questions" "获取语法问题(id=1)"
test_api "GET" "/practice/by-type/vocabulary" "按类型练习-词汇"
test_api "GET" "/practice/by-grammar/1" "按语法练习(id=1)"
test_api "GET" "/practice/mistakes" "获取错误题目"
test_api "GET" "/practice/random" "随机练习"

# 4. 测试复习API
echo ""
echo "4. 测试复习API..."
test_api "POST" "/review/1/next" "进入下一复习项(id=1)"
test_api "POST" "/review/1/retry-original" "重试原始复习项(id=1)"

# 5. 测试统计API
echo ""
echo "5. 测试统计API..."
test_api "GET" "/stats/mistakes-detail" "获取错误详情统计"

# 6. 测试认证API
echo ""
echo "6. 测试认证API..."

# 注册用户
register_data='{"email":"test@example.com","password":"Test123456","name":"测试用户"}'
test_api "POST" "/auth/register" "用户注册" "$register_data"

# 登录用户
login_data='{"email":"test@example.com","password":"Test123456"}'
test_api "POST" "/auth/login" "用户登录" "$login_data"

# 提取token用于后续请求
token_response=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" -d "$login_data")
token=$(echo "$token_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# 获取当前用户信息
if [ -n "$token" ]; then
    test_api "GET" "/auth/me" "获取当前用户信息" "" "Authorization: Bearer $token"
    test_api "POST" "/auth/logout" "用户登出" "" "Authorization: Bearer $token"
else
    echo "  警告: 无法获取token,跳过需要认证的测试"
fi

# 7. 测试管理端API
echo ""
echo "7. 测试管理端API..."
if [ -n "$token" ]; then
    test_api "GET" "/admin/questions" "获取管理端问题列表" "" "Authorization: Bearer $token"
    
    # 导入问题(使用简单的测试数据)
    import_data='{"questions":[{"type":"vocabulary","question":"テスト","answer":"test","level":1}]}'
    test_api "POST" "/admin/import/questions" "导入问题" "$import_data" "Authorization: Bearer $token"
else
    echo "  警告: 无token,跳过管理端测试"
fi

echo ""
echo "========================================="
echo "测试完成!"
echo "总计: $TOTAL_TESTS | 通过: $PASSED_TESTS | 失败: $FAILED_TESTS"
echo "========================================="

# 生成Markdown报告
cat > "$REPORT_FILE" << 'EOF'
# 后端API测试报告

EOF

echo "**测试日期:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT_FILE"
echo "**后端地址:** $BASE_URL" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 总体统计
cat >> "$REPORT_FILE" << EOF
## 总体统计

| 指标 | 数值 |
|------|------|
| 总测试数 | $TOTAL_TESTS |
| 通过数 | $PASSED_TESTS |
| 失败数 | $FAILED_TESTS |
| 通过率 | $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)% |

---

## 详细测试结果

EOF

# 添加详细结果
echo "| API | 端点 | 状态码 | 响应时间 | 状态 |" >> "$REPORT_FILE"
echo "|-----|------|--------|----------|------|" >> "$REPORT_FILE"

for result in "${TEST_RESULTS[@]}"; do
    IFS='|' read -r desc endpoint code time status body <<< "$result"
    echo "| $desc | \`$endpoint\` | $code | ${time}s | $status |" >> "$REPORT_FILE"
done

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "## 失败详情" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 添加失败测试的详细信息
has_failure=false
for result in "${TEST_RESULTS[@]}"; do
    IFS='|' read -r desc endpoint code time status body <<< "$result"
    if [[ "$status" == *"失败"* ]]; then
        has_failure=true
        echo "### ❌ $desc" >> "$REPORT_FILE"
        echo "- **端点:** \`$endpoint\`" >> "$REPORT_FILE"
        echo "- **状态码:** $code" >> "$REPORT_FILE"
        echo "- **响应时间:** ${time}s" >> "$REPORT_FILE"
        echo "- **响应内容:**" >> "$REPORT_FILE"
        echo '```json' >> "$REPORT_FILE"
        echo "$body" | head -c 500 >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
done

if [ "$has_failure" = false ]; then
    echo "无失败测试 ✅" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "*报告生成时间: $(date '+%Y-%m-%d %H:%M:%S')*" >> "$REPORT_FILE"

echo ""
echo "测试报告已生成: $REPORT_FILE"
