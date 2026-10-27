/**
 * 趣味阅读模块 - 前端组件测试
 * Test coverage: NovelPage, NovelDetailPage, FunPage
 * 使用 Vue Test Utils 进行单元测试
 */
import { mount, flushPromises } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import NovelPage from '../pages/NovelPage.vue';
import NovelDetailPage from '../pages/NovelDetailPage.vue';
import FunPage from '../pages/FunPage.vue';
import { useLearningStore } from '../store';

// Mock fetch API
global.fetch = vi.fn();

// Helper: build a proper fetch-style mock response compatible with store.request
// store.request reads response.headers.get('content-length') and response.body
const mockResponse = (data, { ok = true, status = 200 } = {}) => ({
  ok,
  status,
  headers: new Headers({ 'content-length': '0' }),
  body: null,
  json: async () => data,
});

// Helper: mock a fetch that never resolves (for loading state testing)
const pendingResponse = () => ({
  ok: true,
  status: 200,
  headers: new Headers({ 'content-length': '0' }),
  body: null,
  json: async () => new Promise(() => {}), // 永不resolve，保持loading
});

// Mock IntersectionObserver
class MockIntersectionObserver {
  observe() { return null; }
  disconnect() { return null; }
  unobserve() { return null; }
}
Object.defineProperty(window, 'IntersectionObserver', {
  value: MockIntersectionObserver,
  writable: true,
});

// Mock router
const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/novel', component: NovelPage },
    { path: '/novel/:id', component: NovelDetailPage },
    { path: '/fun', component: FunPage },
  ],
});

// Helper: find a button by text content
function findButtonByText(wrapper, text) {
  return wrapper.findAll('button').find(btn => btn.text().includes(text));
}

// Helper: find an anchor by text content
function findAnchorByText(wrapper, text) {
  return wrapper.findAll('a').find(a => a.text().includes(text));
}

describe('NovelPage 组件测试', () => {
  let wrapper;
  let pinia;

  beforeEach(() => {
    pinia = createPinia();
    setActivePinia(pinia);
    fetch.mockClear();
  });

  afterEach(() => {
    if (wrapper) wrapper.unmount();
  });

  it('应该显示加载状态', async () => {
    fetch.mockResolvedValueOnce(pendingResponse());

    wrapper = mount(NovelPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    expect(wrapper.text()).toContain('正在读取章节…');
  });

  it('应该成功加载并显示小说列表', async () => {
    const mockData = {
      title: '小说词汇阅读与练习',
      attribution: '测试作者',
      sourceTitle: '测试来源',
      sourcePages: 100,
      lessons: [
        {
          id: 'novel-1',
          title: '测试小说1',
          category: '长篇小说',
          startPage: 1,
          endPage: 10,
          questionCount: 5,
          vocabularyCount: 20,
        },
        {
          id: 'novel-2',
          title: '测试小说2',
          category: '复合动词',
          startPage: 11,
          endPage: 20,
          questionCount: 3,
          vocabularyCount: 15,
        },
      ],
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(NovelPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('测试小说1');
    expect(wrapper.text()).toContain('测试小说2');
    expect(wrapper.text()).toContain('长篇小说');
    expect(wrapper.text()).toContain('复合动词');
    expect(wrapper.text()).toContain('2 篇');
  });

  it('应该支持按分类筛选', async () => {
    const mockData = {
      title: '测试',
      lessons: [
        { id: '1', title: '长篇1', category: '长篇小说', startPage: 1, endPage: 5, questionCount: 0, vocabularyCount: 10 },
        { id: '2', title: '短篇1', category: '复合动词', startPage: 6, endPage: 10, questionCount: 0, vocabularyCount: 5 },
      ],
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(NovelPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    // 点击"复合动词"分类按钮
    const filterBtn = findButtonByText(wrapper, '复合动词');
    expect(filterBtn).toBeDefined();
    await filterBtn.trigger('click');
    await flushPromises();

    // 应该只显示该分类的内容
    expect(wrapper.text()).toContain('短篇1');
    expect(wrapper.text()).not.toContain('长篇1');
  });

  it('应该支持搜索功能', async () => {
    const mockData = {
      title: '测试',
      lessons: [
        { id: '1', title: '校草的粉红小鸡', category: '长篇小说', startPage: 1, endPage: 5, questionCount: 0, vocabularyCount: 10 },
        { id: '2', title: '家族破产后', category: '长篇小说', startPage: 6, endPage: 10, questionCount: 0, vocabularyCount: 5 },
      ],
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(NovelPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    // 输入搜索关键词
    const searchInput = wrapper.find('input[type="search"]');
    await searchInput.setValue('校草');

    // 应该只显示匹配的结果
    expect(wrapper.text()).toContain('校草的粉红小鸡');
    expect(wrapper.text()).not.toContain('家族破产后');
  });

  it('应该显示错误信息并支持重试', async () => {
    fetch.mockResolvedValueOnce(mockResponse({ error: '服务器错误' }, { ok: false, status: 500 }));

    wrapper = mount(NovelPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('服务器错误');
    const retryBtn = findButtonByText(wrapper, '重试');
    expect(retryBtn).toBeDefined();
  });

  it('应该正确显示来源信息', async () => {
    const mockData = {
      title: '小说词汇阅读与练习',
      attribution: '@叫我とうさん',
      sourceTitle: '看知乎小说背日语N1词汇',
      sourcePages: 298,
      lessons: [],
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(NovelPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('看知乎小说背日语N1词汇');
    expect(wrapper.text()).toContain('298 页');
    expect(wrapper.text()).toContain('@叫我とうさん');
  });

  it('应该生成正确的详情链接', async () => {
    const mockData = {
      title: '测试',
      lessons: [
        { id: 'novel-lesson-01', title: '测试小说', category: '长篇小说', startPage: 1, endPage: 5, questionCount: 0, vocabularyCount: 10 },
      ],
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(NovelPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    const link = wrapper.find('a[href*="novel-lesson-01"]');
    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toContain('/novel/novel-lesson-01');
  });
});

describe('NovelDetailPage 组件测试', () => {
  let wrapper;
  let pinia;

  beforeEach(async () => {
    pinia = createPinia();
    setActivePinia(pinia);
    fetch.mockClear();
    // Navigate to a unique route for each test to avoid state leaks
    router.push('/novel/test-id');
    await router.isReady();
  });

  afterEach(() => {
    if (wrapper) wrapper.unmount();
  });

  it('应该显示加载状态', async () => {
    fetch.mockResolvedValueOnce(pendingResponse());

    wrapper = mount(NovelDetailPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    expect(wrapper.text()).toContain('正在读取章节…');
  });

  it('应该成功加载并显示小说内容', async () => {
    const mockLesson = {
      id: 'test-id',
      title: '测试小说',
      category: '长篇小说',
      note: '测试备注',
      questionCount: 5,
      pages: [
        { pageNumber: 1, text: '第一页内容' },
        { pageNumber: 2, text: '第二页内容' },
      ],
      vocabulary: [
        { word: '测试', reading: 'テスト', meaning: 'test' },
      ],
      published: true,
    };

    fetch.mockResolvedValueOnce(mockResponse(mockLesson));

    wrapper = mount(NovelDetailPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('测试小说');
    expect(wrapper.find('.topbar-title').text()).toBe('测试小说');
    expect(wrapper.find('header').exists()).toBe(false);
    expect(wrapper.text()).toContain('第一页内容');
  });

  it('应该显示词卡面板', async () => {
    const mockLesson = {
      id: 'test-id',
      title: '测试小说',
      category: '长篇小说',
      note: '测试',
      questionCount: 0,
      pages: [],
      vocabulary: [
        { word: '词汇1', meaning: '含义1' },
        { word: '词汇2', meaning: '含义2' },
      ],
      published: true,
    };

    fetch.mockResolvedValueOnce(mockResponse(mockLesson));

    wrapper = mount(NovelDetailPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('本篇词卡（2）');
    expect(wrapper.text()).toContain('词汇1');
    expect(wrapper.text()).toContain('词汇2');
  });

  it('应该从工具栏打开字号面板并同步更新正文', async () => {
    const mockLesson = {
      id: 'test-id',
      title: '测试小说',
      category: '长篇小说',
      note: '测试',
      questionCount: 5,
      paperId: 'test-paper',
      pages: [],
      vocabulary: [],
      published: true,
    };

    fetch
      .mockResolvedValueOnce(mockResponse(mockLesson))
      .mockResolvedValueOnce(mockResponse({ id: 'session-123' }));

    wrapper = mount(NovelDetailPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    await wrapper.find('.topbar-settings').trigger('click');
    await flushPromises();
    const slider = document.querySelector('#reader-font-range');
    expect(slider).not.toBeNull();
    slider.value = '22';
    slider.dispatchEvent(new Event('input', { bubbles: true }));
    await flushPromises();
    expect(wrapper.find('.pages-container').attributes('style')).toContain('22px');
    expect(document.querySelector('#reader-font-settings').getAttribute('aria-modal')).toBe('true');
  });

  it('应该支持关闭字号面板并返回工具栏', async () => {
    const mockLesson = {
      id: 'test-id',
      title: '测试小说',
      category: '长篇小说',
      note: '测试',
      questionCount: 0,
      pages: [],
      vocabulary: [],
      published: false,
    };

    fetch.mockResolvedValueOnce(mockResponse(mockLesson));

    wrapper = mount(NovelDetailPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    await wrapper.find('.topbar-settings').trigger('click');
    await flushPromises();
    expect(document.querySelector('#reader-font-settings')).not.toBeNull();
    document.querySelector('[aria-label="关闭字号设置"]').click();
    await flushPromises();
    expect(document.querySelector('#reader-font-settings')).toBeNull();
    expect(wrapper.find('.topbar-settings').attributes('aria-expanded')).toBe('false');
  });

  it('应该显示返回按钮', async () => {
    const mockLesson = {
      id: 'test-id',
      title: '测试小说',
      category: '长篇小说',
      note: '测试',
      questionCount: 0,
      pages: [],
      vocabulary: [],
      published: true,
    };

    fetch.mockResolvedValueOnce(mockResponse(mockLesson));

    wrapper = mount(NovelDetailPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    const backLink = wrapper.find('a[href="/novel"]');
    expect(backLink.exists()).toBe(true);
    expect(backLink.text()).toContain('返回');
    expect(backLink.attributes('aria-label')).toBe('返回趣味阅读目录');
  });

  it('应该处理404错误', async () => {
    // Reset router to a fresh state for this test
    router.push('/novel/test-id-404');
    await router.isReady();
    
    fetch.mockResolvedValueOnce(mockResponse({ error: '小说章节不存在' }, { ok: false, status: 404 }));

    wrapper = mount(NovelDetailPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();
    // Wait a bit more for all promises to settle
    await new Promise(resolve => setTimeout(resolve, 10));

    expect(wrapper.text()).toContain('小说章节不存在');
  });
});

describe('FunPage 组件测试', () => {
  let wrapper;
  let pinia;

  beforeEach(() => {
    pinia = createPinia();
    setActivePinia(pinia);
    fetch.mockClear();
  });

  afterEach(() => {
    if (wrapper) wrapper.unmount();
  });

  it('应该显示加载状态', async () => {
    fetch.mockResolvedValueOnce(pendingResponse());

    wrapper = mount(FunPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    expect(wrapper.text()).toContain('正在读取题组…');
  });

  it('应该成功加载并显示趣味题组', async () => {
    const mockData = {
      papers: [
        {
          id: 'fun-1',
          title: '趣味题组1',
          description: '描述1',
          theme: '主题A',
          questionCount: 5,
          ready: true,
          readingLessonId: 'novel-1',
        },
        {
          id: 'fun-2',
          title: '趣味题组2',
          description: '描述2',
          theme: '主题B',
          questionCount: 3,
          ready: false,
          readingLessonId: null,
        },
      ],
      label: '用户素材改编练习',
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(FunPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('趣味题组1');
    expect(wrapper.text()).toContain('趣味题组2');
    expect(wrapper.text()).toContain('主题A');
    expect(wrapper.text()).toContain('主题B');
    expect(wrapper.text()).toContain('2 组');
  });

  it('应该按主题筛选', async () => {
    const mockData = {
      papers: [
        { id: '1', title: '题组1', description: '', theme: 'A', questionCount: 5, ready: true },
        { id: '2', title: '题组2', description: '', theme: 'B', questionCount: 3, ready: true },
      ],
      label: '测试',
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(FunPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    const themeBtn = findButtonByText(wrapper, 'B');
    expect(themeBtn).toBeDefined();
    await themeBtn.trigger('click');
    await flushPromises();

    expect(wrapper.text()).toContain('题组2');
    expect(wrapper.text()).not.toContain('题组1');
  });

  it('应该在题组未完整时禁用开始按钮', async () => {
    const mockData = {
      papers: [
        { id: '1', title: '题组1', description: '', theme: 'A', questionCount: 5, ready: false },
      ],
      label: '测试',
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(FunPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    const startBtn = findButtonByText(wrapper, '开始闯关');
    expect(startBtn).toBeDefined();
    expect(startBtn.attributes('disabled')).toBeDefined();
    expect(wrapper.text()).toContain('题组尚未完整入库');
  });

  it('应该提供"先读原文"链接', async () => {
    const mockData = {
      papers: [
        {
          id: '1',
          title: '题组1',
          description: '',
          theme: 'A',
          questionCount: 5,
          ready: true,
          readingLessonId: 'novel-1',
        },
      ],
      label: '测试',
    };

    fetch.mockResolvedValueOnce(mockResponse(mockData));

    wrapper = mount(FunPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    const readLink = findAnchorByText(wrapper, '先读原文');
    expect(readLink).toBeDefined();
    expect(readLink.attributes('href')).toContain('/novel/novel-1');
  });

  it('应该显示错误信息并支持重新加载', async () => {
    fetch.mockResolvedValueOnce(mockResponse({ error: '服务错误' }, { ok: false, status: 500 }));

    wrapper = mount(FunPage, {
      global: {
        plugins: [pinia, router],
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('服务错误');
    const reloadBtn = findButtonByText(wrapper, '重新加载');
    expect(reloadBtn).toBeDefined();
  });
});
