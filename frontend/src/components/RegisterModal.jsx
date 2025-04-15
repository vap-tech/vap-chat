import React, { useState } from 'react';
import Modal from '@mui/material/Modal';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import axios from 'axios';

const RegisterModal = ({ open, onClose }) => {
  const [login, setLogin] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const validateUsername = (value) => {
    if (!/^[a-zA-Z0-9.]+$/.test(value)) {
      alert("Имя пользователя должно содержать только буквы, цифры и точку");
      return false;
    }
    return true;
  };

  const validateEmail = (value) => {
    if (!/\S+@\S+\.\S+/.test(value)) {
      alert("Некорректный адрес электронной почты");
      return false;
    }
    return true;
  };

  const validatePassword = (value) => {
    if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{6,}/.test(value)) {
      alert(
        "Пароль должен содержать минимум 6 символов, одну заглавную букву, одну строчную букву и цифру."
      );
      return false;
    }
    return true;
  };

  const handleSubmitRegistration = async (event) => {
    event.preventDefault();
    if (!validateUsername(login) || !validateEmail(email) || !validatePassword(password)) return;

    try {
      await axios.post('/register', { login, email, password }, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  });
      alert('Регистрация прошла успешно!');
      onClose(); // Закрываем модалочку
    } catch (err) {
      console.error(err.response.data.message || err.message);
      alert('Ошибка регистрации');
    }
  };

  return (
    <Modal open={open} onClose={onClose}>
      <Box p={3} borderRadius={5} bgcolor="white" maxWidth="300px" mx="auto">
        <Typography variant="h6">Регистрация</Typography>
        <form onSubmit={handleSubmitRegistration}>
          <TextField
            label="Имя пользователя"
            type="text"
            value={login}
            onChange={(e) => setLogin(e.target.value)}
            required
            fullWidth
            margin="normal"
          />
          <TextField
            label="Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            fullWidth
            margin="normal"
          />
          <TextField
            label="Пароль"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            fullWidth
            margin="normal"
          />
          <Button variant="contained" color="primary" type="submit">
            Зарегистрироваться
          </Button>
        </form>
      </Box>
    </Modal>
  );
};

export default RegisterModal;