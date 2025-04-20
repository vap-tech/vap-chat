import axios from "axios";

export async function updateTokensIfNeeded(cookies, removeCookie) {
    if (!cookies.access_token || Date.now() > parseInt(cookies.expiration_time)) {
        await axios.post('/api/v1/refresh', {
            credentials: 'include', // Обязателен для передачи cookie
            }).then(function (response) {
                console.log(response);
            }).catch(function (error) {
                console.log('Ошибка при получении токенов:', error);
                // Очищаем cookie с access_token, если возникли проблемы с обновлением
                removeCookie('access_token');
            });
    }
}
