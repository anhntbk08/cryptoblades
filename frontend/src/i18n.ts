import Vue from 'vue';
import VueI18n from 'vue-i18n';

Vue.use(VueI18n);

//remove emtpy locale strings to use fallback locale strings
const removeEmpty = (obj: { [x: string]: any; }): any =>
  Object.keys(obj)
    .filter((k: string) => obj[k] !== null && obj[k] !== undefined && obj[k] !== '') // Remove undef. and null and empty.string.
    .reduce(
      (newObj, k) =>
        typeof obj[k] === 'object'
          ? Object.assign(newObj, { [k]: removeEmpty(obj[k]) })
          : Object.assign(newObj, { [k]: obj[k] }),
      {},
    );

function loadLocaleMessages() {
  const locales = require.context(
    './locales',
    true,
    /[A-Za-z0-9-_,\s]+\.json$/i
  );
  const messages: any = {};
  locales.keys().forEach(key => {
    const matched = key.match(/([A-Za-z0-9-_]+)\./i);
    if (matched && matched.length > 1) {
      const locale = matched[1];
      messages[locale] = removeEmpty(locales(key));
    }
  });
  console.log(messages);
  return messages;
}

export default new VueI18n({
  locale: localStorage.getItem('language') || 'en',
  fallbackLocale: 'en',
  messages: loadLocaleMessages()
});
