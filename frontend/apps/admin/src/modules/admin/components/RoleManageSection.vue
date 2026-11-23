<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { Delete, EditPen } from '@element-plus/icons-vue'
import AdminPageHeader from '@/modules/admin/components/AdminPageHeader.vue'
import { adminRoleApi } from '@/modules/admin/api'
import type { RoleCreateDTO, RoleUpdateDTO, RoleVO } from '@/modules/admin/types'

interface RoleForm {
  roleName: string
  roleCode: string
  description: string
  enabled: boolean
}

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()
const list = ref<RoleVO[]>([])

const form = reactive<RoleForm>({
  roleName: '',
  roleCode: '',
  description: '',
  enabled: true,
})

const rules: FormRules<RoleForm> = {
  roleCode: [{ required: true, message: '请输入角色编码', trigger: 'blur' },
    { pattern: /^[A-Z][A-Z0-9_]{1,63}$/, message: '2-64 位大写字母、数字或下划线，以字母开头', trigger: 'blur' }],
  roleName: [
    { required: true, message: '请输入角色名', trigger: 'blur' },
    { max: 100, message: '角色名不能超过 100 字符', trigger: 'blur' },
  ],
  description: [{ max: 255, message: '描述不能超过 255 字符', trigger: 'blur' }],
}

const fetchList = async () => {
  loading.value = true
  try {
    const res = await adminRoleApi.list()
    list.value = res.data ?? []
  } catch (error) {
    ElMessage.error((error as Error).message || '加载角色列表失败')
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  editingId.value = null
  form.roleName = ''
  form.roleCode = ''
  form.description = ''
  form.enabled = true
  formRef.value?.clearValidate()
}

const openCreate = () => {
  resetForm()
  dialogVisible.value = true
}

const openEdit = (row: RoleVO) => {
  editingId.value = row.id
  form.roleName = row.roleName
  form.roleCode = row.roleCode
  form.description = row.description ?? ''
  form.enabled = row.enabled
  formRef.value?.clearValidate()
  dialogVisible.value = true
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (editingId.value !== null) {
      const payload: RoleUpdateDTO = {
        roleName: form.roleName,
        description: form.description || undefined,
        enabled: editingId.value !== null && list.value.find(role => role.id === editingId.value)?.builtIn ? undefined : form.enabled,
      }
      await adminRoleApi.update(editingId.value, payload)
      ElMessage.success('角色已更新')
    } else {
      const payload: RoleCreateDTO = {
        roleCode: form.roleCode,
        roleName: form.roleName,
        description: form.description || undefined,
        enabled: form.enabled,
      }
      await adminRoleApi.create(payload)
      ElMessage.success('角色已创建')
    }
    dialogVisible.value = false
    await fetchList()
  } catch (error) {
    ElMessage.error((error as Error).message || '保存失败，请稍后重试')
  } finally {
    submitting.value = false
  }
}

const toggleEnabled = async (row: RoleVO) => {
  try {
    await adminRoleApi.updateEnabled(row.id, !row.enabled)
    ElMessage.success(row.enabled ? '角色已禁用' : '角色已启用')
    await fetchList()
  } catch (error) {
    ElMessage.error((error as Error).message || '操作失败，请稍后重试')
  }
}

const remove = async (row: RoleVO) => {
  try {
    await ElMessageBox.confirm(`确定删除角色「${row.roleName}」吗？删除后不可恢复。`, '删除确认', {
      type: 'warning',
      confirmButtonText: '删除',
      cancelButtonText: '取消',
    })
    await adminRoleApi.deleteById(row.id)
    ElMessage.success('角色已删除')
    await fetchList()
  } catch (error) {
    if (error !== 'cancel' && error !== 'close') {
      ElMessage.error((error as Error).message || '删除失败，请稍后重试')
    }
  }
}

const permissionRole = ref<RoleVO | null>(null)
const catalog = ref<import('@/modules/admin/types').PermissionInfo[]>([])
const selectedPermissions = ref<string[]>([])
const permissionSubmitting = ref(false)
const groupedPermissions = computed(() => {
  const groups = new Map<string, typeof catalog.value>()
  for (const item of catalog.value) {
    if (!groups.has(item.module)) groups.set(item.module, [])
    groups.get(item.module)!.push(item)
  }
  return [...groups.entries()]
})
const openPermissions = async (row: RoleVO) => {
  try {
    const [directory, assigned] = await Promise.all([adminRoleApi.permissions(), adminRoleApi.rolePermissions(row.id)])
    catalog.value = directory.data
    selectedPermissions.value = assigned.data
    permissionRole.value = row
  } catch (error) { ElMessage.error((error as Error).message) }
}
const savePermissions = async () => {
  if (!permissionRole.value) return
  permissionSubmitting.value = true
  try {
    await adminRoleApi.replacePermissions(permissionRole.value.id, selectedPermissions.value)
    permissionRole.value = null
    ElMessage.success('权限已更新，关联用户需要重新登录')
  } catch (error) { ElMessage.error((error as Error).message) }
  finally { permissionSubmitting.value = false }
}

onMounted(fetchList)
</script>

<template>
  <div class="manage-panel">
    <AdminPageHeader
      title="角色管理"
      subtitle="后台角色维护与启停控制"
      action-label="新增角色"
      @action="openCreate"
    />

    <div class="manage-panel__card">
    <div class="manage-panel__table-wrap">
      <el-table v-if="!loading || list.length" :data="list" class="manage-panel__table">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="roleCode" label="角色编码" min-width="160" />
        <el-table-column prop="roleName" label="角色名" min-width="180" show-overflow-tooltip />
        <el-table-column prop="description" label="描述" min-width="280" show-overflow-tooltip />
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag class="manage-panel__status-tag" :type="row.enabled ? 'success' : 'info'" effect="light">
              {{ row.enabled ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" min-width="170" show-overflow-tooltip />
        <el-table-column prop="updateTime" label="更新时间" min-width="170" show-overflow-tooltip />
        <el-table-column label="操作" width="300" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" :icon="EditPen" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="!row.builtIn" link type="primary" @click="openPermissions(row)">配置权限</el-button>
            <el-button v-if="!row.builtIn" link :type="row.enabled ? 'warning' : 'success'" @click="toggleEnabled(row)">
              {{ row.enabled ? '禁用' : '启用' }}
            </el-button>
            <el-button v-if="!row.builtIn" link type="danger" :icon="Delete" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-skeleton v-else-if="loading" :rows="5" animated class="manage-panel__skeleton" />

      <el-empty v-else description="暂无角色" />
    </div>
    </div>

    <el-dialog :model-value="permissionRole !== null" :title="`配置权限：${permissionRole?.roleName ?? ''}`" width="min(720px, 92vw)" @close="permissionRole = null">
      <p>保存后，关联用户需要重新登录。操作权限会自动包含对应的查看权限和后台入口权限。</p>
      <el-checkbox-group v-model="selectedPermissions">
        <section v-for="[module, items] in groupedPermissions" :key="module" style="margin-bottom: 16px">
          <strong style="display: block">{{ module }}</strong>
          <el-checkbox v-for="item in items" :key="item.code" :value="item.code">{{ item.name }}</el-checkbox>
        </section>
      </el-checkbox-group>
      <template #footer>
        <el-button @click="permissionRole = null">取消</el-button>
        <el-button type="primary" :loading="permissionSubmitting" @click="savePermissions">保存</el-button>
      </template>
    </el-dialog>
    <el-dialog
      v-model="dialogVisible"
      :title="editingId !== null ? '编辑角色' : '新增角色'"
      width="min(560px, 92vw)"
      destroy-on-close
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="角色编码" prop="roleCode">
          <el-input v-model="form.roleCode" :disabled="editingId !== null" maxlength="64" placeholder="例如 CONTENT_EDITOR" />
        </el-form-item>
        <el-form-item label="角色名" prop="roleName">
          <el-input v-model="form.roleName" maxlength="100" show-word-limit />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="4" maxlength="255" show-word-limit />
        </el-form-item>
        <el-form-item label="启用" prop="enabled">
          <el-switch :disabled="editingId !== null && list.find(role => role.id === editingId)?.builtIn" v-model="form.enabled" />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>


