<script setup lang="ts">
import { logout } from '@kite/platform/auth'
import { useRouter } from 'vue-router'
const router = useRouter()
async function switchAccount() { await logout(); await router.replace('/login') }
</script>
<template><main class="status-page"><h1>没有访问权限</h1><p>当前账号没有此页面的访问权限。</p> <button type="button" @click="switchAccount">切换账号</button></main></template>
<style scoped>.status-page { padding: 80px 24px; text-align: center; }</style>
