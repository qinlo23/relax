<script setup lang="ts">
import LoginForm from '@kite/ui/login-form'
defineProps<{ modelValue: boolean }>()
const emit = defineEmits<{ 'update:modelValue': [value: boolean] }>()
function onAuthenticated() {
  emit('update:modelValue', false)
}
</script>
<template>
  <el-dialog :model-value="modelValue" width="1000px" @update:model-value="emit('update:modelValue', $event)">
    <LoginForm @authenticated="onAuthenticated" />
  </el-dialog>
</template>
