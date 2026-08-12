# intangible_track


| time cost| work |
|----------|------|
|3h|依赖配置、启动页与应用图标配置|
|8h|视觉稿UI基础页面还原、Mock数据测试|
|5h|核心地图组件封装，支持移动、缩放、选中高亮并自适应大小、名称标注|
|4h|地图名称标注算法优化，世界地图优先使用Natural Earth官方校准的LABEL_X / LABEL_Y，回退算法为计算面积质心；中国地图使用Mapbox polylabel 算法计算各省内切圆圆心|