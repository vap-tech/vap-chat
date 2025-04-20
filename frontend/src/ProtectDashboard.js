import React, {useEffect} from 'react';
import {useCookies} from 'react-cookie';
import AuthFormSwitcher from './AuthFormSwitcher/AuthFormSwitcher';
import Dashboard from './Dashboard/Dashboard';
import {updateTokensIfNeeded} from './authUtils';

export default function ProtectDashboard() {
    const [cookies, , removeCookie] = useCookies(['access_token']); // Вызываем useCookies на верхнем уровне

    useEffect(() => {
        // если кука существует, но истекла
        if (cookies.access_token && Date.now() >= parseInt(cookies.expiration_time)) {
            updateTokensIfNeeded(cookies, removeCookie).then(r => console.log("хз что этот код делает")); // то идём на сервер за новой
        }
    }, []);

    const tokenIsValid =
        cookies.access_token && 1 // а если существует
        //Date.now() <= parseInt(cookies.expiration_time); // и не истекла

    return tokenIsValid ? <Dashboard /> : <AuthFormSwitcher />; // то рисуем боард, иначе форму входа
}