var store = {
    selectedFiles: null
};

document.addEventListener('DOMContentLoaded', () => {
    new Vue({
        el: '#vue-app-div',
        data: store,
        methods: {
            fileInputChanged: function (event) {
                store.selectedFiles = event.target.files
            }
        }
    });
});