import React from 'react';
import '../css/Connect.css';
import { useWeb3React } from '@web3-react/core'
import { Web3Provider } from '@ethersproject/providers'
import { InjectedConnector } from '@web3-react/injected-connector'


export default function Connect() {
  const injectedConnector = new InjectedConnector({supportedChainIds: [1,3, 4, 5, 42, ],});
  const { chainId, account, activate, active,library } = useWeb3React();
  
  const handleClick = () => {
    activate(injectedConnector)
  }

  const shortenAddress = (address) => {
    return `${address.substring(0,6)}...`;
  }

  return (
    <>
    {active ? (
      <button class="connect-button">{shortenAddress(account)}</button>
    ) : (
      <button class="connect-button" onClick={handleClick}>Connect</button>
    )
    
  
  }
      
    </>
  )
}
