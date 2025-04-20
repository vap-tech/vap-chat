import * as React from 'react';
import Container from '@mui/material/Container';
import Typography from '@mui/material/Typography';
import Link from '@mui/material/Link';
import ProtectDashboard from './ProtectDashboard';
import {CookiesProvider} from "react-cookie";

function Copyright() {
  return (
    <Typography
      variant="body2"
      align="center"
      sx={{
        color: 'text.secondary',
      }}
    >
      {'Copyright © '}
      <Link color="inherit" href="http://localhost/">
        vap-chat
      </Link>{' '}
      {new Date().getFullYear()}
      {'.'}
    </Typography>
  );
}

export default function App() {
  return (
      <CookiesProvider>
        <Container component="main">
          <ProtectDashboard></ProtectDashboard>
          <Copyright></Copyright>
        </Container>
      </CookiesProvider>
  )
}
