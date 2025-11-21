# Library Management System

A small full-stack library management system with a Rails API backend and a Vite + React (TypeScript) frontend. Features include authentication with librarian/member roles, book catalog CRUD, borrowing/return flows, and dashboards for both user types.

## Backend (Ruby on Rails API)
- Location: `backend/`
- Structure:
  - `lib/library/data_store.rb` – in-memory persistence for users, books, borrowings, and tokens (no external DB required).
  - `lib/library/*` – authentication, book management, borrowing, dashboard services, and a registry to share them.
  - `config/` – Rails API configuration, CORS, routes, and Puma server (port `4567`).
  - `app/controllers` – Rails controllers exposing the REST API endpoints.
- Key endpoints (port `4567`):
  - `POST /register`, `POST /login`, `POST /logout`
  - `GET /books`, `POST /books`, `PUT|PATCH /books/:id`, `DELETE /books/:id`
  - `POST /books/:id/borrow`, `POST /borrowings/:id/return`
  - `GET /borrowings`, `GET /dashboard`, `GET /health`

### Setup & Run
```bash
cd backend
bundle install
bundle exec rails server --port 4567

# Optional: pre-seed the in-memory database with sample users/books for quick testing
SEED_SAMPLE_DATA=1 bundle exec rails server --port 4567
```

- CORS: The API allows cross-origin calls from `CORS_ORIGIN` (defaults to `http://localhost:5173`). If you set
  `CORS_ORIGIN="*"`, credentialed requests are disabled for safety.

### Seeding test data
- The in-memory store ships with reusable presets defined in `lib/library/seed_data.rb`.
- Use `SEED_SAMPLE_DATA=1` to load seed data at boot. Pick a preset with `SEED_PRESET=demo` (default) or `SEED_PRESET=test`.
- You can also load seeds ad-hoc without running the server:
  ```bash
  cd backend
  SEED_PRESET=test bundle exec rails db:seed
  ```

Demo preset users for quick UI testing:
- Librarian: `librarian@example.com` / `password`
- Member: `member@example.com` / `password`

Test preset users (overdue + returned examples for dashboards):
- Librarian: `librarian@test.com` / `password`
- Members: `member@test.com`, `member2@test.com` (password `password`)

### Tests
RSpec covers authentication, authorization, book management, borrowing rules, and dashboards.
```bash
cd backend
bundle exec rspec
```

## Frontend (Vite + React + TypeScript)
- Location: `frontend/`
- Uses Vite for tooling and a minimal component-based UI for login/registration, book search, librarian CRUD, borrowing/return actions, and role-specific dashboards.
- Configure API target via `VITE_API_URL` (defaults to `http://localhost:4567`).

### Setup & Run
```bash
cd frontend
npm install
npm run dev # launches Vite dev server on http://localhost:5173
```

Build for production with `npm run build`, then serve `frontend/dist/` with any static server.
