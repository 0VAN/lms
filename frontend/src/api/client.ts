export type UserRole = 'librarian' | 'member';

export interface Session {
  token: string;
  user: { id: number; email: string; role: UserRole };
}

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:4567';

async function request<T>(path: string, options: RequestInit = {}, token?: string): Promise<T> {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(options.headers || {})
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const response = await fetch(`${API_URL}${path}`, { ...options, headers });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error || 'Request failed');
  }
  return data as T;
}

export const api = {
  async register(email: string, password: string, role: UserRole): Promise<{ id: number; email: string; role: UserRole }> {
    return request('/register', { method: 'POST', body: JSON.stringify({ email, password, role }) });
  },
  async login(email: string, password: string): Promise<Session> {
    return request('/login', { method: 'POST', body: JSON.stringify({ email, password }) });
  },
  async logout(token: string): Promise<void> {
    await request('/logout', { method: 'POST' }, token);
  },
  async listBooks(query: { title?: string; author?: string; genre?: string }): Promise<any[]> {
    const params = new URLSearchParams();
    Object.entries(query).forEach(([key, value]) => {
      if (value) params.append(key, value);
    });
    const search = params.toString();
    return request(`/books${search ? `?${search}` : ''}`);
  },
  async addBook(token: string, book: any): Promise<any> {
    return request('/books', { method: 'POST', body: JSON.stringify(book) }, token);
  },
  async updateBook(token: string, id: number, book: any): Promise<any> {
    return request(`/books/${id}`, { method: 'PUT', body: JSON.stringify(book) }, token);
  },
  async deleteBook(token: string, id: number): Promise<any> {
    return request(`/books/${id}`, { method: 'DELETE' }, token);
  },
  async borrowBook(token: string, id: number): Promise<any> {
    return request(`/books/${id}/borrow`, { method: 'POST', body: JSON.stringify({}) }, token);
  },
  async returnBorrowing(token: string, id: number): Promise<any> {
    return request(`/borrowings/${id}/return`, { method: 'POST', body: JSON.stringify({}) }, token);
  },
  async borrowings(token: string): Promise<any[]> {
    return request('/borrowings', { method: 'GET' }, token);
  },
  async dashboard(token: string): Promise<any> {
    return request('/dashboard', { method: 'GET' }, token);
  }
};
