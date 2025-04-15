import React, { useState } from 'react';
import './App.css'; // Импортируем стили приложения
import AuthForm from './components/AuthForm';
import { ThemeProvider } from '@mui/material/styles';
import { LightTheme, DarkTheme } from './themes';
import ThemeSwitcher from './components/ThemeSwitcher'; // Переключатель


// Основной компонент приложения
const App = () => {

    const [currentTheme, setCurrentTheme] = useState(LightTheme); // Начинаем со светлой темы

  const toggleTheme = () => {
    setCurrentTheme(currentTheme === LightTheme ? DarkTheme : LightTheme);
  };

    return (
      <ThemeProvider theme={currentTheme}>
    <div className="App">
      <header className="App-header">
        <h1>Messenger</h1>
      </header>
      <section className="content">
        <AuthForm />
      </section>

    </div>
          <ThemeSwitcher onToggle={toggleTheme} />
      </ThemeProvider>
  );
};

export default App;