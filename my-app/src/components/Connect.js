import React, {useEffect} from 'react';
import '../css/Connect.css';
import { useWeb3React } from '@web3-react/core'
import { Web3Provider } from '@ethersproject/providers'
import { InjectedConnector } from '@web3-react/injected-connector'
import {ethers} from 'ethers';


export default function Connect() {
  const injectedConnector = new InjectedConnector({ supportedChainIds: [1, 3, 4, 5, 42,], });
  //const { chainId, account, activate, active, library } = useWeb3React();
  const {
    account,
    activate,
    active,
    chainId,
    connector,
    deactivate,
    error,
    provider,
    setError,
    library,
} = useWeb3React();

  const handleClick = async (connector) => {
    activate(injectedConnector)
    // read-only
    let ethersProvider = new ethers.providers.JsonRpcProvider(process.env.API_ENDPOINT);
    let { provider } = await connector.activate();
    // signer
    const signer = provider.getSigner;
    ethersProvider = new Web3Provider(signer);
  }

  useEffect(() => {
    console.log("Chain: " + chainId, "Account: " + account, "Active: " + active);
    },);

  const shortenAddress = (address) => {
    return `${address.substring(0, 6)}...`;
  }

  return (
    <>
      {active ? (
        <button class="connect-button" onClick={deactivate}>{shortenAddress(account)}</button>
      ) : (
        <button class="connect-button" onClick={() => handleClick(injectedConnector)}>Connect</button>
      )


      }

    </>
  )
}
