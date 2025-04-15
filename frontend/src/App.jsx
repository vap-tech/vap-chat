import React from 'react';
import './App.css'; // Импортируем стили приложения
import AuthForm from './components/AuthForm';

// Основной компонент приложения
const App = () => {
  return (
    <div className="App">
      <header className="App-header">
        <h1>Messenger</h1>
      </header>
      <section className="content">
        <AuthForm />
      </section>
    </div>
  );
};

export default App;