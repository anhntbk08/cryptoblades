<template>
  <b-tabs v-if="hasAccessToAnyTab" justified content-class="mt-3"> <!-- note, use "vertical" if too many tabs -->
    <AdminTab v-for="tab in tabs" :key="tab.title" :title="tab.title" :contract="tab.contract"
              :component="tab.component"/>
  </b-tabs>
</template>

<script lang="ts">
import Vue from 'vue';
import {mapGetters, mapState} from 'vuex';
import {Contract} from '@/interfaces';
import AdminTab from '@/components/smart/AdminTab.vue';

interface Tab {
  title: string;
  contract: Contract<any>;
  component: string;
}

interface Data {
  tabs: Tab[];
}

export default Vue.extend({
  components: {AdminTab},

  computed: {
    ...mapGetters(['contracts', 'getHasAdminAccess', 'getHasMinterAccess']),
    ...mapState(['defaultAccount']),

    hasAccessToAnyTab(): boolean {
      return this.getHasAdminAccess || this.getHasMinterAccess;
    },
  },

  data() {
    return {
      tabs: [] as Tab[],
    } as Data;
  },

  async mounted() {
    this.tabs.push({
      title: 'quests',
      contract: this.contracts.SimpleQuests,
      component: 'QuestsAdmin',
    });
    this.tabs.push({
      title: 'cbkLand',
      contract: this.contracts.CBKLand,
      component: 'CBKLandAdmin',
    });
    this.tabs.push({
      title: 'weapons',
      contract: this.contracts.Weapons,
      component: 'WeaponsAdmin',
    });
    this.tabs.push({
      title: 'burningManager',
      contract: this.contracts.BurningManager,
      component: 'BurningManagerAdmin',
    });
    this.tabs.push({
      title: 'partnerVault',
      contract: this.contracts.PartnerVault,
      component: 'PartnerVaultAdmin',
    });
  },
});
</script>

<style scoped lang="scss">
</style>
