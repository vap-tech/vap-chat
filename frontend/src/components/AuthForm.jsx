import React, { useState } from 'react';
import axios from 'axios';
import Modal from '@mui/material/Modal';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import FormControlLabel from '@mui/material/FormControlLabel';
import Checkbox from '@mui/material/Checkbox';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import RegisterModal from "./RegisterModal";

const AuthForm = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [openRegister, setOpenRegister] = useState(false);

  // Обработчик отправки формы регистрации
  const handleSubmitAuth = async (event) => {
    event.preventDefault();
    try {
      await axios.post('/auth', { email, password });
      alert('Авторизация успешна!');
    } catch (err) {
      console.error(err.response.data.message || err.message);
      alert('Ошибка авторизации');
    }
  };

  return (
    <>
      <form onSubmit={handleSubmitAuth}>
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
          Войти
        </Button>
        <Button
          variant="outlined"
          color="secondary"
          style={{ marginLeft: '1rem' }}
          onClick={() => setOpenRegister(true)}
        >
          Регистрация
        </Button>
      </form>
      <RegisterModal open={openRegister} onClose={() => setOpenRegister(false)} />
    </>
  );
};

export default AuthForm;