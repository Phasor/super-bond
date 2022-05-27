import '../css/App.css';
import Nav from './Nav';
import Main from './Main';
import React, {useState} from 'react';


function App() {
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();

  const setProviderAndSigner = (provider,signer) => {
    setProvider(provider);
    setSigner(signer);
  }

  return (
    <div className="App">
      <Nav providerAndSigner={setProviderAndSigner}/>
      <Main provider={provider} signer={signer} />
    </div>
  );
}

export default App;
