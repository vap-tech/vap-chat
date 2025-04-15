// components/ThemeSwitcher.jsx
import React from 'react';
import Switch from '@mui/material/Switch';
import Tooltip from '@mui/material/Tooltip';
import "./styles.css"

const ThemeSwitcher = ({ onToggle }) => {
  return (
    <Tooltip title="Переключить тему">
      <Switch onChange={onToggle} />
    </Tooltip>
  );
};

export default ThemeSwitcher;