// themes.js
import { createTheme } from '@mui/material/styles';

export const LightTheme = createTheme({
  palette: {
    primary: {
      main: '#5F9EA0', // Основной акцентный цвет
    },
    secondary: {
      main: '#FFD700', // Вторичный цвет
    },
    error: {
      main: '#ff4444', // Цвет ошибок
    },
    warning: {
      main: '#ffb300', // Предупреждения
    },
    info: {
      main: '#2196f3', // Информационный цвет
    },
    success: {
      main: '#4caf50', // Успех
    },
    background: {
      paper: '#fff', // Фон элементов
      default: '#eee', // Общий фон
    },
    text: {
      primary: '#333', // Основной текст
      secondary: '#777', // Второстепенный текст
    },
  },
});

export const DarkTheme = createTheme({
  palette: {
    primary: {
      main: '#95d1d3', // Основной акцентный цвет
    },
    secondary: {
      main: '#00ff15', // Вторичный цвет
    },
    error: {
      main: '#ff4444', // Цвет ошибок
    },
    warning: {
      main: '#ffb300', // Предупреждения
    },
    info: {
      main: '#2196f3', // Информационный цвет
    },
    success: {
      main: '#4caf50', // Успех
    },
    background: {
      paper: '#d39494', // Фон элементов
      default: '#373030', // Общий фон
    },
    text: {
      primary: '#f4f4f4', // Основной текст
      secondary: '#9bc897', // Второстепенный текст
    },
  },
});