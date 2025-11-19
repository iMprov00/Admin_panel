document.addEventListener('DOMContentLoaded', function() {
    // Подтверждение удаления
    const deleteButtons = document.querySelectorAll('.btn-delete');
    deleteButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            if (!confirm('Вы уверены, что хотите удалить эту службу?')) {
                e.preventDefault();
            }
        });
    });

    // Автообновление статусов каждые 10 секунд
    setInterval(() => {
        fetch(window.location.href)
            .then(response => response.text())
            .then(html => {
                const parser = new DOMParser();
                const newDoc = parser.parseFromString(html, 'text/html');
                const newServices = newDoc.querySelector('.services-grid');
                if (newServices) {
                    document.querySelector('.services-grid').innerHTML = newServices.innerHTML;
                    // Перепривязываем события
                    bindEvents();
                }
            })
            .catch(error => console.error('Ошибка автообновления:', error));
    }, 10000);

    function bindEvents() {
        // Перепривязываем события для новых элементов
        document.querySelectorAll('.btn-delete').forEach(button => {
            button.addEventListener('click', function(e) {
                if (!confirm('Вы уверены, что хотите удалить эту службу?')) {
                    e.preventDefault();
                }
            });
        });
    }

    // Анимация загрузки для кнопок
    document.querySelectorAll('form').forEach(form => {
        form.addEventListener('submit', function() {
            const submitBtn = this.querySelector('button[type="submit"], input[type="submit"]');
            if (submitBtn) {
                submitBtn.innerHTML = '<span>Загрузка...</span>';
                submitBtn.disabled = true;
            }
        });
    });
});