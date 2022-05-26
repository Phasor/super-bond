import React from 'react'
import '../css/Nav.css'
import Connect from './Connect';

export default function Nav() {
  return (
    <div class="nav-container">
        <div className="connect-container">
            <Connect/>
        </div>
    </div>
  )
}
