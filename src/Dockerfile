FROM nginx:1.17.10

WORKDIR /app
COPY nginx.conf .
COPY start.sh .

EXPOSE 5000
CMD ["./start.sh"]
