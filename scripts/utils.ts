import axios from "axios";

export const pinJSONToIPFS = async (
  pinataApiKey: string,
  pinataSecretApiKey: string,
  JSONBody: any
) => {
  const url = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;

  const response = await axios.post(url, JSONBody, {
    headers: {
      pinata_api_key: pinataApiKey,
      pinata_secret_api_key: pinataSecretApiKey,
    },
  });
  return response;
};
