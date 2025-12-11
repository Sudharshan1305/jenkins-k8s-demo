# Use official nginx base image
FROM nginx:alpine

# Copy a custom index.html
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]