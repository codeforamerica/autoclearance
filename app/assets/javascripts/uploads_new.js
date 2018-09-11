var store = {
    selectedFiles: null
};

document.addEventListener('DOMContentLoaded', function () {
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