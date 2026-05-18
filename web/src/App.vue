<script setup lang="ts">
import { onMounted, ref } from "vue";
import { apiGet } from "./api";

type Health = { ok: boolean; db: boolean };

const status = ref<Health | null>(null);
const error = ref<string | null>(null);

onMounted(async () => {
  try {
    status.value = await apiGet<Health>("/health");
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e);
  }
});
</script>

<template>
  <main>
    <h1>AQ Emissions Assessment</h1>
    <p>This page is a placeholder. Replace it with your own views.</p>

    <section>
      <h2>Backend health</h2>
      <pre v-if="status">{{ status }}</pre>
      <p
        v-else-if="error"
        class="error"
      >
        error: {{ error }}
      </p>
      <p v-else>
        loading…
      </p>
    </section>
  </main>
</template>

<style>
body { font-family: system-ui, sans-serif; margin: 2rem; }
pre { background: #f4f4f4; padding: 0.75rem; border-radius: 4px; }
.error { color: #b00020; }
</style>
