FROM node as BUILDER
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build-prod

FROM node:alpine3.19
RUN addgroup -g 1001 -S nextjs
RUN adduser -S nextjs -u 1001

COPY --from=BUILDER --chown=nextjs:nextjs /app/.next ./.next
COPY --from=BUILDER --chown=nextjs:nextjs /app/node_modules ./node_modules
COPY --from=BUILDER --chown=nextjs:nextjs /app/package.json ./package.json
COPY --from=BUILDER --chown=nextjs:nextjs /app/public ./public

USER nextjs
EXPOSE 3000 
CMD ["npm", "start"]

