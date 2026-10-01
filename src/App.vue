<script setup lang="ts">
import { getVersion } from "@tauri-apps/api/app";
import { getCurrentWindow } from "@tauri-apps/api/window";
import IconMdiHome from "~icons/mdi/home";
import IconMdiPlaylistPlay from "~icons/mdi/playlist-play";
import IconMdiDownload from "~icons/mdi/download";
import IconMdiToolbox from "~icons/mdi/toolbox";
import type { Component } from "vue";
import { useThemeVars } from "naive-ui";
import { useSettingStore } from "@/stores/setting";
import { useDownloadStore } from "@/stores/download";
import { usePendingStore } from "@/stores/pending";
import { localeEntries } from "@/locales";
import { useExternalImports } from "@/composables/useExternalImports";
import { useTrayManager } from "@/composables/useTrayManager";
import { useAppBootstrap } from "@/composables/useAppBootstrap";

const router = useRouter();
const route = useRoute();
const settingStore = useSettingStore();
const downloadStore = useDownloadStore();
const pendingStore = usePendingStore();
const themeVars = useThemeVars();
const showDonateModal = ref(false);

const { bootstrap } = useAppBootstrap();
const { setupTray, handleQuitRequest } = useTrayManager();
const { setupExternalImportListeners } = useExternalImports();

const navBadgeCounts = computed<Record<string, number>>(() => ({
  pending: pendingStore.items.length,
  downloads: downloadStore.tasks.filter(
    (downloadTask) =>
      downloadTask.status === "downloading" ||
      downloadTask.status === "postprocessing" ||
      downloadTask.status === "queued",
  ).length,
}));

const localeOptions = localeEntries.map((localeEntry) => ({
  label: `${localeEntry.flag} ${localeEntry.label}`,
  value: localeEntry.code,
}));

const currentRoute = computed(() => {
  const routeName = (route.name as string) ?? "";
  if (routeName.startsWith("toolbox")) return "toolbox";
  return routeName;
});

const navItems: { key: string; icon: Component; labelKey: string }[] = [
  { key: "home", icon: IconMdiHome, labelKey: "nav.home" },
  { key: "pending", icon: IconMdiPlaylistPlay, labelKey: "nav.pending" },
  { key: "downloads", icon: IconMdiDownload, labelKey: "nav.downloads" },
  { key: "toolbox", icon: IconMdiToolbox, labelKey: "nav.toolbox" },
];

const currentAppWindow = getCurrentWindow();

/** 当前应用版本号 */
const appVersion = ref("");

// 窗口关闭事件拦截
currentAppWindow.onCloseRequested(async (closeEvent) => {
  if (settingStore.showTrayIcon && settingStore.closeToTray) {
    closeEvent.preventDefault();
    await currentAppWindow.hide();
  } else {
    closeEvent.preventDefault();
    handleQuitRequest();
  }
});

onMounted(async () => {
  appVersion.value = await getVersion().catch(() => "");
  try {
    await bootstrap();
    await setupExternalImportListeners();
    await setupTray();
  } finally {
    // 引导失败也要显示窗口，否则应用只剩托盘图标、看不到界面
    await currentAppWindow.show();
  }
});
</script>

<template>
  <Provider>
    <CookieModal />
    <UpdateModal />
    <SetupModal />
    <MigrationModal />
    <DonateModal v-model:show="showDonateModal" />
    <n-layout style="height: 100vh">
      <n-layout-header bordered class="app-header">
        <div class="header-side">
          <div class="logo" @click="router.push({ name: 'home' })">
            <img src="/app-icon.svg" alt="" class="logo-img" />
            <div class="logo-titles">
              <span class="logo-text">Bitdo Downloader</span>
              <n-text v-if="appVersion" depth="3" class="logo-version">v{{ appVersion }}</n-text>
            </div>
          </div>
        </div>
        <div class="header-nav">
          <n-badge
            v-for="item in navItems"
            :key="item.key"
            :value="navBadgeCounts[item.key] || 0"
            :max="99"
            :show="(navBadgeCounts[item.key] || 0) > 0"
            :color="themeVars.primaryColor"
            :offset="[-6, 4]"
          >
            <n-button
              :quaternary="currentRoute !== item.key"
              :type="currentRoute === item.key ? 'primary' : 'default'"
              :secondary="currentRoute === item.key"
              :focusable="false"
              round
              @click="router.push({ name: item.key })"
            >
              <template #icon>
                <n-icon>
                  <component :is="item.icon" />
                </n-icon>
              </template>
              <span class="nav-label" :class="{ expanded: currentRoute === item.key }">
                {{ $t(item.labelKey) }}
              </span>
            </n-button>
          </n-badge>
        </div>
        <div class="header-side header-side-right">
          <n-button
            :focusable="false"
            quaternary
            round
            class="donate-header-button"
            :aria-label="$t('donate.button')"
            :title="$t('donate.button')"
            @click="showDonateModal = true"
          >
            <span class="donate-header-content">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                height="24px"
                viewBox="0 -960 960 960"
                width="24px"
                fill="#EA3323"
                aria-hidden="true"
                class="donate-header-icon"
              >
                <path d="M640-440 474-602q-31-30-52.5-66.5T400-748q0-55 38.5-93.5T532-880q32 0 60 13.5t48 36.5q20-23 48-36.5t60-13.5q55 0 93.5 38.5T880-748q0 43-21 79.5T807-602L640-440Zm0-112 109-107q19-19 35-40.5t16-48.5q0-22-15-37t-37-15q-14 0-26.5 5.5T700-778l-60 72-60-72q-9-11-21.5-16.5T532-800q-22 0-37 15t-15 37q0 27 16 48.5t35 40.5l109 107ZM280-220l278 76 238-74q-5-9-14.5-15.5T760-240H558q-27 0-43-2t-33-8l-93-31 22-78 81 27q17 5 40 8t68 4q0-11-6.5-21T578-354l-234-86h-64v220ZM40-80v-440h304q7 0 14 1.5t13 3.5l235 87q33 12 53.5 42t20.5 66h80q50 0 85 33t35 87v40L560-60l-280-78v58H40Zm80-80h80v-280h-80v280Zm520-546Z" />
              </svg>
              <span>Donate</span>
            </span>
          </n-button>
          <n-popselect
            v-model:value="settingStore.locale"
            :options="localeOptions"
            trigger="click"
            scrollable
          >
            <n-button :focusable="false" quaternary circle>
              <template #icon>
                <n-icon>
                  <icon-mdi-translate />
                </n-icon>
              </template>
            </n-button>
          </n-popselect>
          <n-button
            :type="currentRoute === 'settings' ? 'primary' : 'default'"
            :secondary="currentRoute === 'settings'"
            :quaternary="currentRoute !== 'settings'"
            :focusable="false"
            circle
            @click="router.push({ name: 'settings' })"
          >
            <template #icon>
              <n-icon>
                <icon-mdi-cog />
              </n-icon>
            </template>
          </n-button>
        </div>
      </n-layout-header>
      <n-layout
        position="absolute"
        style="top: 56px; bottom: 32px"
        content-style="display: flex; flex-direction: column; height: 100%; overflow: hidden;"
        :native-scrollbar="false"
      >
        <div class="app-route-view">
          <router-view v-slot="{ Component: RouteComponent }">
            <Transition name="fade-slide" mode="out-in">
              <component :is="RouteComponent" />
            </Transition>
          </router-view>
        </div>
      </n-layout>
      <AppStatusBar />
    </n-layout>
  </Provider>
</template>

<style scoped lang="scss">
.app-header {
  height: 56px;
  display: flex;
  align-items: center;
  padding: 0 16px;

  .header-side {
    width: 120px;
    flex-shrink: 0;
    display: flex;
    align-items: center;

    &.header-side-right {
      justify-content: flex-end;
      gap: 4px;
    }

    .donate-header-button {
      padding: 0 10px;
    }

    .donate-header-content {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-weight: 600;
      line-height: 1;
    }

    .donate-header-icon {
      width: 20px;
      height: 20px;
      flex: none;
    }
  }

  .logo {
    display: flex;
    align-items: center;
    gap: 8px;
    user-select: none;
    cursor: pointer;

    .logo-img {
      width: 26px;
      height: 26px;
      transition: transform 0.3s;
    }

    .logo-titles {
      display: flex;
      flex-direction: column;
      justify-content: center;
      min-width: 0;
    }

    .logo-text {
      font-weight: 700;
      font-size: 16px;
      line-height: 1.15;
      letter-spacing: 0.5px;
    }

    .logo-version {
      font-size: 11px;
      line-height: 1.2;
      letter-spacing: 0.2px;
      font-variant-numeric: tabular-nums;
    }

    &:hover .logo-img {
      transform: scale(1.06);
    }
  }

  .header-nav {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 4px;

    :deep(.n-button) {
      .n-button__content {
        overflow: visible;
        transition:
          max-width 0.2s ease,
          opacity 0.2s ease;
      }

      .n-button__icon {
        margin-right: 0;
      }

      &:not(.n-button--color) .n-button__icon {
        margin-left: 0;
      }
    }

    .nav-label {
      display: inline-block;
      max-width: 0;
      opacity: 0;
      overflow: hidden;
      white-space: nowrap;
      line-height: normal;
      padding-bottom: 0.18em;
      margin-bottom: -0.18em;
      transition:
        max-width 0.2s ease,
        opacity 0.2s ease,
        margin 0.2s ease;
      margin-left: 0;

      &.expanded {
        max-width: 80px;
        opacity: 1;
        margin-left: 4px;
      }
    }
  }
}

.app-route-view {
  flex: 1;
  height: 100%;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
</style>
