<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import LoginForm from '@kite/ui/login-form'
import { loginDestination } from '@/core/router'
const route = useRoute()
const router = useRouter()
function onAuthenticated() { void router.replace(loginDestination(route.query.redirect)) }
</script>
<template>
  <main class="admin-login">
    <section class="admin-login__card">
      <h1>管理后台登录</h1>
      <LoginForm @authenticated="onAuthenticated" />
    </section>
  </main>
</template>
<style scoped lang="scss">
.admin-login { min-height: 100vh; display: grid; place-items: center; padding: var(--spacing-lg); }
.admin-login__card { width: min(100%, 1000px); padding: var(--spacing-lg); background: var(--color-surface); border-radius: var(--radius-soft-lg); box-shadow: var(--shadow-soft); }
h1 { text-align: center; }
</style>
