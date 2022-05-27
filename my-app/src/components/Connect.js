import React from 'react';
import { useState } from "react";
import '../css/Connect.css';
import { ethers } from "ethers";


export default function Connect(props) {
  const [address, setAddress] = useState();
  const [shortAddress, setShortAddress] = useState();

  // A Web3Provider wraps a standard Web3 provider, which is
  // what MetaMask injects as window.ethereum into each page
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  // The MetaMask plugin also allows signing transactions to
  // send ether and pay to change state within the blockchain.
  // For this, you need the account signer...
  const signer = provider.getSigner()

  // MetaMask requires requesting permission to connect users accounts
  const requestConnection = async () => {
    await provider.send("eth_requestAccounts", []);
    const connectedAddress = await signer.getAddress();

    //set provider and signer in App component
    const setProviderAndSigner = props.providerAndSigner;
    await setProviderAndSigner(provider,signer);

    //set local variables for display purposes
    const shortAddress = connectedAddress.substring(0, 7);
    setAddress(connectedAddress);
    setShortAddress(shortAddress);
  } 

  return (
    <>
      {!address && <button class="connect-button" onClick={requestConnection}>Connect</button>}
      {address && <button class="connect-button" onClick={() => window.location.reload(false)}>{shortAddress}...</button>}
    </>
  )
}
