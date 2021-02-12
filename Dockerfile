FROM ruby:3.0-alpine

RUN apk add --update --no-cache alpine-sdk openssl-dev glib vips nginx

RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
  && chown -R nginx /var/lib/nginx

WORKDIR /app

RUN gem install foreman

RUN mkdir -p /run/nginx
RUN mkdir -p /data/nginx

COPY Gemfile Gemfile.lock /app/
RUN bundle install

COPY . .
ADD config/nginx-sites.conf /etc/nginx/http.d/default.conf

CMD ["sh", "-c", "foreman start -f Procfile"]
