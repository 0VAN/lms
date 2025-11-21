import React, { useEffect, useMemo, useState } from 'react';
import { api, Session, UserRole } from './api/client';

interface Book {
  id: number;
  title: string;
  author: string;
  genre: string;
  isbn: string;
  total_copies: number;
}

interface Borrowing {
  id: number;
  book_id: number;
  user_id: number;
  borrowed_at: string;
  due_date: string;
  returned_at: string | null;
}

const roles: UserRole[] = ['member', 'librarian'];

const App: React.FC = () => {
  const [session, setSession] = useState<Session | null>(null);
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [form, setForm] = useState({ email: '', password: '', role: 'member' as UserRole });
  const [books, setBooks] = useState<Book[]>([]);
  const [bookForm, setBookForm] = useState({ title: '', author: '', genre: '', isbn: '', total_copies: 1 });
  const [search, setSearch] = useState({ title: '', author: '', genre: '' });
  const [borrowings, setBorrowings] = useState<Borrowing[]>([]);
  const [dashboard, setDashboard] = useState<any | null>(null);
  const [error, setError] = useState<string | null>(null);

  const isLibrarian = useMemo(() => session?.user.role === 'librarian', [session]);

  const handleAuth = async () => {
    setError(null);
    try {
      if (mode === 'login') {
        const auth = await api.login(form.email, form.password);
        setSession(auth);
      } else {
        await api.register(form.email, form.password, form.role);
        const auth = await api.login(form.email, form.password);
        setSession(auth);
      }
    } catch (err: any) {
      setError(err.message);
    }
  };

  const loadBooks = async () => {
    try {
      const data = await api.listBooks(search);
      setBooks(data as Book[]);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const loadBorrowings = async () => {
    if (!session) return;
    try {
      const data = await api.borrowings(session.token);
      setBorrowings(data as Borrowing[]);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const loadDashboard = async () => {
    if (!session) return;
    try {
      const data = await api.dashboard(session.token);
      setDashboard(data);
    } catch (err: any) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadBooks();
  }, []);

  useEffect(() => {
    if (session) {
      loadBorrowings();
      loadDashboard();
    } else {
      setBorrowings([]);
      setDashboard(null);
    }
  }, [session]);

  const handleAddBook = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!session) return;
    try {
      await api.addBook(session.token, { ...bookForm, total_copies: Number(bookForm.total_copies) });
      setBookForm({ title: '', author: '', genre: '', isbn: '', total_copies: 1 });
      await loadBooks();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleBorrow = async (bookId: number) => {
    if (!session) return;
    try {
      await api.borrowBook(session.token, bookId);
      await Promise.all([loadBooks(), loadBorrowings(), loadDashboard()]);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleReturn = async (borrowingId: number) => {
    if (!session) return;
    try {
      await api.returnBorrowing(session.token, borrowingId);
      await Promise.all([loadBorrowings(), loadDashboard()]);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleDeleteBook = async (id: number) => {
    if (!session) return;
    try {
      await api.deleteBook(session.token, id);
      await loadBooks();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const logout = async () => {
    if (!session) return;
    await api.logout(session.token);
    setSession(null);
  };

  return (
    <div className="page">
      <header className="header">
        <div>
          <h1>Library Management</h1>
          <p className="muted">Responsive dashboard for librarians and members</p>
        </div>
        {session ? (
          <div className="user-chip">
            <span>{session.user.email}</span>
            <span className="pill">{session.user.role}</span>
            <button onClick={logout}>Logout</button>
          </div>
        ) : null}
      </header>

      {!session && (
        <section className="card">
          <div className="card-header">
            <h2>{mode === 'login' ? 'Login' : 'Register'}</h2>
            <button className="ghost" onClick={() => setMode(mode === 'login' ? 'register' : 'login')}>
              Switch to {mode === 'login' ? 'Register' : 'Login'}
            </button>
          </div>
          <div className="grid">
            <label>
              Email
              <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
            </label>
            <label>
              Password
              <input
                type="password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
              />
            </label>
            {mode === 'register' && (
              <label>
                Role
                <select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value as UserRole })}>
                  {roles.map((r) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))}
                </select>
              </label>
            )}
          </div>
          <div className="actions">
            <button onClick={handleAuth}>{mode === 'login' ? 'Login' : 'Register'}</button>
          </div>
          {error && <p className="error">{error}</p>}
        </section>
      )}

      <section className="card">
        <div className="card-header">
          <h2>Books</h2>
          <div className="search-row">
            <input
              placeholder="Title"
              value={search.title}
              onChange={(e) => setSearch({ ...search, title: e.target.value })}
            />
            <input
              placeholder="Author"
              value={search.author}
              onChange={(e) => setSearch({ ...search, author: e.target.value })}
            />
            <input
              placeholder="Genre"
              value={search.genre}
              onChange={(e) => setSearch({ ...search, genre: e.target.value })}
            />
            <button onClick={loadBooks}>Search</button>
          </div>
        </div>
        <div className="grid books">
          {books.map((book) => (
            <div className="card book" key={book.id}>
              <div className="card-header">
                <div>
                  <h3>{book.title}</h3>
                  <p className="muted">{book.author}</p>
                </div>
                <span className="pill">{book.genre}</span>
              </div>
              <p className="muted">ISBN: {book.isbn}</p>
              <div className="actions">
                <span>Copies: {book.total_copies}</span>
                {session?.user.role === 'member' && <button onClick={() => handleBorrow(book.id)}>Borrow</button>}
                {isLibrarian && (
                  <>
                    <button className="ghost" onClick={() => handleDeleteBook(book.id)}>
                      Delete
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      </section>

      {isLibrarian && (
        <section className="card">
          <div className="card-header">
            <h2>Add Book</h2>
          </div>
          <form className="grid" onSubmit={handleAddBook}>
            <label>
              Title
              <input value={bookForm.title} onChange={(e) => setBookForm({ ...bookForm, title: e.target.value })} />
            </label>
            <label>
              Author
              <input value={bookForm.author} onChange={(e) => setBookForm({ ...bookForm, author: e.target.value })} />
            </label>
            <label>
              Genre
              <input value={bookForm.genre} onChange={(e) => setBookForm({ ...bookForm, genre: e.target.value })} />
            </label>
            <label>
              ISBN
              <input value={bookForm.isbn} onChange={(e) => setBookForm({ ...bookForm, isbn: e.target.value })} />
            </label>
            <label>
              Total Copies
              <input
                type="number"
                min={1}
                value={bookForm.total_copies}
                onChange={(e) => setBookForm({ ...bookForm, total_copies: Number(e.target.value) })}
              />
            </label>
            <div className="actions">
              <button type="submit">Save</button>
            </div>
          </form>
        </section>
      )}

      {session && (
        <section className="card">
          <div className="card-header">
            <h2>Borrowings</h2>
            <p className="muted">{session.user.role === 'librarian' ? 'All borrowings' : 'Your borrowings'}</p>
          </div>
          <div className="table">
            <div className="table-row header">
              <span>Book ID</span>
              <span>User ID</span>
              <span>Due</span>
              <span>Status</span>
              {isLibrarian && <span>Actions</span>}
            </div>
            {borrowings.map((b) => (
              <div className="table-row" key={b.id}>
                <span>{b.book_id}</span>
                <span>{b.user_id}</span>
                <span>{new Date(b.due_date).toLocaleDateString()}</span>
                <span className={b.returned_at ? 'muted' : 'pill warn'}>
                  {b.returned_at ? 'Returned' : 'Active'}
                </span>
                {isLibrarian && !b.returned_at && (
                  <span>
                    <button onClick={() => handleReturn(b.id)}>Mark Returned</button>
                  </span>
                )}
              </div>
            ))}
          </div>
        </section>
      )}

      {dashboard && (
        <section className="card">
          <div className="card-header">
            <h2>Dashboard</h2>
          </div>
          {isLibrarian ? (
            <div className="grid four">
              <div className="stat">
                <p className="muted">Total Books</p>
                <strong>{dashboard.total_books}</strong>
              </div>
              <div className="stat">
                <p className="muted">Borrowed</p>
                <strong>{dashboard.total_borrowed}</strong>
              </div>
              <div className="stat">
                <p className="muted">Due Today</p>
                <strong>{dashboard.due_today}</strong>
              </div>
              <div className="stat">
                <p className="muted">Overdue Members</p>
                <strong>{dashboard.overdue_members.length}</strong>
              </div>
              <div className="table full">
                <div className="table-row header">
                  <span>Member</span>
                  <span>Overdue</span>
                </div>
                {dashboard.overdue_members.map((m: any) => (
                  <div className="table-row" key={m.id}>
                    <span>{m.email}</span>
                    <span className="pill warn">Overdue</span>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="table">
              <div className="table-row header">
                <span>Book</span>
                <span>Due</span>
                <span>Status</span>
              </div>
              {dashboard.borrowed.map((b: any, idx: number) => (
                <div className="table-row" key={idx}>
                  <span>{b.book}</span>
                  <span>{new Date(b.due_date).toLocaleDateString()}</span>
                  <span className={b.overdue ? 'pill warn' : 'pill'}>{b.overdue ? 'Overdue' : 'On Track'}</span>
                </div>
              ))}
            </div>
          )}
        </section>
      )}
    </div>
  );
};

export default App;
