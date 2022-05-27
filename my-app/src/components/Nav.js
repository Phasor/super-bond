import React from 'react'
import '../css/Nav.css'
import Connect from './Connect';

export default function Nav(props) {


  return (
    <div class="nav-container">
        <div className="connect-container">
            <Connect providerAndSigner={props.providerAndSigner}/>
        </div>
    </div>
  )
}
