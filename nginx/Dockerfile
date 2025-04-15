# Используем официальный образ Nginx
FROM nginx:alpine

# Копируем настроенный нами конфиг nginx.conf в контейнер
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Запускаем Nginx
CMD ["nginx", "-g", "daemon off;"]