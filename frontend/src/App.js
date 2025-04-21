import * as React from 'react';
import Container from '@mui/material/Container';
import ProtectDashboard from './ProtectDashboard';
import {CookiesProvider} from "react-cookie";


export default function App() {
  return (
      <CookiesProvider>
        <Container component="main">
          <ProtectDashboard></ProtectDashboard>
        </Container>
      </CookiesProvider>
  )
}
