<script setup lang="ts">
import { writeText } from "@tauri-apps/plugin-clipboard-manager";
import { useI18n } from "vue-i18n";
import { donateMethods } from "@/config/donate";
import type { DonateMethod } from "@/config/donate";

const show = defineModel<boolean>("show", { required: true });
const { t } = useI18n();
const selectedId = ref<DonateMethod["id"] | null>(null);
const copiedValue = ref<string | null>(null);
const selectedMethod = computed(() => donateMethods.find((method) => method.id === selectedId.value));
let copyTimer: ReturnType<typeof setTimeout> | undefined;

const copyValue = async (value: string) => {
  try {
    await writeText(value);
    copiedValue.value = value;
    if (copyTimer) clearTimeout(copyTimer);
    copyTimer = setTimeout(() => (copiedValue.value = null), 1800);
  } catch {
    window.$message.error(t("clipboard.writeFailed"));
  }
};

watch(show, (isOpen) => {
  if (!isOpen) {
    selectedId.value = null;
    copiedValue.value = null;
  }
});

onUnmounted(() => {
  if (copyTimer) clearTimeout(copyTimer);
});
</script>

<template>
  <n-modal
    v-model:show="show"
    preset="card"
    :title="t('donate.title')"
    :bordered="false"
    content-scrollable
    :style="{ width: '500px', maxWidth: 'calc(100vw - 32px)', maxHeight: '80vh' }"
  >
    <div v-if="!selectedMethod" class="donate-overview">
      <n-text depth="3">{{ t("donate.intro") }}</n-text>
      <div class="donate-methods">
        <n-button
          v-for="method in donateMethods"
          :key="method.id"
          secondary
          class="donate-method"
          @click="selectedId = method.id"
        >
          <span class="donate-method-content">
            <img :src="method.icon" alt="" class="method-icon" />
            <span>{{ t(method.titleKey) }}</span>
          </span>
        </n-button>
      </div>
    </div>

    <div v-else class="donate-details">
      <n-button text @click="selectedId = null">
        <template #icon><n-icon><icon-mdi-arrow-left /></n-icon></template>
        {{ t("common.back") }}
      </n-button>
      <div class="selected-method">
        <img :src="selectedMethod.icon" alt="" class="method-icon" />
        <strong>{{ t(selectedMethod.titleKey) }}</strong>
      </div>
      <div class="qr-panel">
        <img
          :src="selectedMethod.qr"
          :alt="t('donate.qrAlt', { method: t(selectedMethod.titleKey) })"
          class="qr-image"
        />
        <n-text depth="3" class="qr-caption">{{ t("donate.scanQr") }}</n-text>
      </div>
      <div v-for="detail in selectedMethod.details" :key="detail.labelKey" class="detail-row">
        <n-text depth="3" class="detail-label">{{ t(detail.labelKey) }}</n-text>
        <div class="detail-value">
          <span>{{ detail.value }}</span>
          <n-button
            quaternary
            circle
            size="small"
            :aria-label="t('donate.copyValue', { label: t(detail.labelKey) })"
            :title="copiedValue === detail.value ? t('donate.copied') : t('donate.copyValue', { label: t(detail.labelKey) })"
            @click="copyValue(detail.value)"
          >
            <template #icon>
              <n-icon v-if="copiedValue === detail.value" color="#18a058">
                <icon-mdi-check />
              </n-icon>
              <n-icon v-else><icon-mdi-content-copy /></n-icon>
            </template>
          </n-button>
        </div>
      </div>
      <n-text v-if="selectedMethod.noteKey" depth="3" class="donate-note">
        {{ t(selectedMethod.noteKey) }}
      </n-text>
    </div>

    <template #action>
      <n-flex justify="end">
        <n-button @click="show = false">{{ t("donate.close") }}</n-button>
      </n-flex>
    </template>
  </n-modal>
</template>

<style scoped lang="scss">
.donate-overview,
.donate-details {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.donate-methods {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.donate-method {
  width: 100%;
  height: 72px;
}

.donate-method-content,
.selected-method {
  display: flex;
  align-items: center;
  gap: 10px;
}

.selected-method {
  font-size: 16px;
}

.method-icon {
  width: 34px;
  height: 34px;
  flex: none;
}

.qr-panel {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 14px;
  border: 1px solid var(--n-border-color);
  border-radius: 14px;
  background: rgb(255 255 255 / 4%);
}

.qr-image {
  width: min(220px, 68vw);
  height: min(220px, 68vw);
  object-fit: contain;
  border-radius: 12px;
  background: #fff;
  padding: 10px;
}

.qr-caption {
  font-size: 12px;
}

.detail-row {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.detail-label {
  font-size: 12px;
}

.detail-value {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  overflow-wrap: anywhere;
}

.detail-value span {
  min-width: 0;
}

.donate-note {
  font-size: 12px;
  line-height: 1.5;
}

@media (max-width: 420px) {
  .donate-methods {
    grid-template-columns: 1fr;
  }
}
</style>
