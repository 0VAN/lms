# Library Management System

A small full-stack library management system with a Sinatra API backend and a Vite + React (TypeScript) frontend. Features include authentication with librarian/member roles, book catalog CRUD, borrowing/return flows, and dashboards for both user types.

## Backend (Ruby + Sinatra)
- Location: `backend/`
- Structure:
  - `lib/library/data_store.rb` – in-memory persistence for users, books, borrowings, and tokens.
  - `lib/library/authentication.rb` – registration, login, logout, and token handling.
  - `lib/library/book_management.rb` – librarian-only CRUD and searching.
  - `lib/library/borrowing.rb` – member borrowing rules and librarian returns.
  - `lib/library/dashboard.rb` – aggregates role-based dashboard data.
  - `app.rb` – Sinatra API wiring all services together.
- Key endpoints (port `4567`):
  - `POST /register`, `POST /login`, `POST /logout`
  - `GET /books`, `POST /books`, `PUT|PATCH /books/:id`, `DELETE /books/:id`
  - `POST /books/:id/borrow`, `POST /borrowings/:id/return`
  - `GET /borrowings`, `GET /dashboard`, `GET /health`

### Setup & Run
```bash
cd backend
bundle install
bundle exec ruby app.rb # runs on http://localhost:4567 using an in-memory data store

# Optional: pre-seed the in-memory database with sample users/books for quick testing
SEED_SAMPLE_DATA=1 bundle exec ruby app.rb
```

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
