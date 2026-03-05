
FROM nginx:stable-alpine

# Copy hasil build aplikasi
COPY dist /usr/share/nginx/html

# Copy konfigurasi Nginx custom kita (TIMPA config default)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

