FROM nginx:alpine


RUN rm -rf /usr/share/nginx/html/*

# Copy your HTML file into nginx directory
COPY index.html /usr/share/nginx/html/

EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
