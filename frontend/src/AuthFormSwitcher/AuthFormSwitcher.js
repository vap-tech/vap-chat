// AuthFormSwitcher.jsx
import React, { useState } from 'react';
import SignIn from './SignIn/SignIn'; // Ваша форма входа
import SignUp from './SignUp/SignUp'; // Ваша форма регистрации

export default function AuthFormSwitcher() {
    const [showLogin, setShowLogin] = useState(true);

    const handleSwitch = () => {
        setShowLogin(!showLogin);
    };

    return (
        <div>
            {showLogin ? (
                <SignIn switchToSignup={handleSwitch} />
            ) : (
                <SignUp switchToLogin={handleSwitch} />
            )}
        </div>
    );
}