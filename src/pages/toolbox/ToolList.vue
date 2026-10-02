<script setup lang="ts">
import type { Component } from "vue";
import IconMdiImageOutline from "~icons/mdi/image-outline";
import IconMdiSubtitlesOutline from "~icons/mdi/subtitles-outline";
import IconMdiMessageTextOutline from "~icons/mdi/message-text-outline";
import IconMdiFormatListNumbered from "~icons/mdi/format-list-numbered";
import IconMdiCommentTextMultipleOutline from "~icons/mdi/comment-text-multiple-outline";
import IconMdiAccountBoxMultipleOutline from "~icons/mdi/account-box-multiple-outline";
import IconMdiPuzzleOutline from "~icons/mdi/puzzle-outline";
import IconMdiOpenInApp from "~icons/mdi/open-in-app";
import IconMdiMovieEditOutline from "~icons/mdi/movie-edit-outline";
import { openUrl } from "@tauri-apps/plugin-opener";
import { useI18n } from "vue-i18n";

useI18n();
const router = useRouter();

interface ToolItem {
  key: string;
  icon: Component;
  color: string;
  bg: string;
  titleKey?: string;
  descKey?: string;
  title?: string;
  desc?: string;
  tagKey?: string;
  externalUrl?: string;
}

const tools: ToolItem[] = [
  {
    key: "channel",
    icon: IconMdiAccountBoxMultipleOutline,
    color: "#0ea5e9",
    bg: "rgba(14,165,233,0.1)",
    titleKey: "channelArchive.title",
    descKey: "toolbox.channelArchiveDesc",
  },
  {
    key: "thumbnail",
    icon: IconMdiImageOutline,
    color: "#18a058",
    bg: "rgba(24,160,88,0.1)",
    titleKey: "toolbox.thumbnailTitle",
    descKey: "toolbox.thumbnailDesc",
  },
  {
    key: "subtitles",
    icon: IconMdiSubtitlesOutline,
    color: "#2080f0",
    bg: "rgba(32,128,240,0.1)",
    titleKey: "toolbox.subtitlesTitle",
    descKey: "toolbox.subtitlesDesc",
  },
  {
    key: "livechat",
    icon: IconMdiMessageTextOutline,
    color: "#f0a020",
    bg: "rgba(240,160,32,0.1)",
    titleKey: "toolbox.livechatTitle",
    descKey: "toolbox.livechatDesc",
    tagKey: "toolbox.youtubeOnly",
  },
  {
    key: "chapters",
    icon: IconMdiFormatListNumbered,
    color: "#d946ef",
    bg: "rgba(217,70,239,0.1)",
    titleKey: "toolbox.chaptersTitle",
    descKey: "toolbox.chaptersDesc",
  },
  {
    key: "comments",
    icon: IconMdiCommentTextMultipleOutline,
    color: "#ef4444",
    bg: "rgba(239,68,68,0.1)",
    titleKey: "toolbox.commentsTitle",
    descKey: "toolbox.commentsDesc",
    tagKey: "toolbox.youtubeOnly",
  },
  {
    key: "plugins",
    icon: IconMdiPuzzleOutline,
    color: "#8b5cf6",
    bg: "rgba(139,92,246,0.1)",
    titleKey: "plugins.title",
    descKey: "plugins.desc",
  },

  {
    key: "capcut-automate",
    icon: IconMdiMovieEditOutline,
    color: "#00d4aa",
    bg: "rgba(0,212,170,0.12)",
    title: "Capcut Automate",
    desc: "Tự động hóa edit CapCut PC: đồng bộ video với audio, thêm chuyển cảnh, hiệu ứng và nhiều thao tác lặp lại.",
    externalUrl: "https://capcutpilot.com/download",
  },
  {
    key: "create-subtitles",
    icon: IconMdiSubtitlesOutline,
    color: "#f97316",
    bg: "rgba(249,115,22,0.12)",
    title: "Create Subtitles",
    desc: "Công cụ tạo phụ đề chất lượng cao, chuẩn chính tả, phù hợp cho video dài và nội dung đa nền tảng.",
    externalUrl: "https://shopbitdo.com/product/smartsub-editor",
  },
  {
    key: "browser-extension",
    icon: IconMdiOpenInApp,
    color: "#06b6d4",
    bg: "rgba(6,182,212,0.1)",
    titleKey: "toolbox.browserExtTitle",
    descKey: "toolbox.browserExtDesc",
    tagKey: "browserExt.tagBeta",
  },
];

const handleToolClick = async (tool: ToolItem) => {
  if (tool.externalUrl) {
    await openUrl(tool.externalUrl);
    return;
  }

  router.push({ name: `toolbox-${tool.key}` });
};
</script>

<template>
  <div>
    <div class="tools-grid">
      <n-card
        v-for="tool in tools"
        :key="tool.key"
        size="small"
        hoverable
        class="tool-card"
        @click="handleToolClick(tool)"
      >
        <n-flex align="center" :size="10" :wrap="false">
          <div class="tool-icon" :style="{ background: tool.bg }">
            <n-icon :size="20" :color="tool.color">
              <component :is="tool.icon" />
            </n-icon>
          </div>
          <n-flex vertical :size="2" class="tool-info">
            <n-flex align="center" :size="6" :wrap="false">
              <n-text strong class="tool-title">{{ tool.title ?? $t(tool.titleKey ?? "") }}</n-text>
              <n-tag v-if="tool.tagKey" size="small" round :bordered="false" type="warning">
                {{ $t(tool.tagKey) }}
              </n-tag>
            </n-flex>
            <n-text depth="3" class="tool-desc">{{ tool.desc ?? $t(tool.descKey ?? "") }}</n-text>
          </n-flex>
          <n-icon :size="16" class="tool-arrow" :depth="3">
            <icon-mdi-chevron-right />
          </n-icon>
        </n-flex>
      </n-card>
    </div>
  </div>
</template>

<style scoped lang="scss">
.tools-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 16px;
}

.tool-card {
  cursor: pointer;
}

.tool-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.tool-info {
  flex: 1;
  min-width: 0;

  .tool-title {
    flex: 0 1 auto;
    min-width: 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .tool-desc {
    font-size: 12px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
}

.tool-arrow {
  flex-shrink: 0;
  opacity: 0.4;
  transition:
    opacity 0.15s,
    transform 0.15s;
}
</style>
