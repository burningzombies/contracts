import axios from "axios";

export const pinJSONToIPFS = async (JSONBody: any) => {
  const url = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;

  const response = await axios.post(url, JSONBody, {
    headers: {
      pinata_api_key: process.env.PINATA_API_KEY as string,
      pinata_secret_api_key: process.env.PINATA_API_SECRET as string,
    },
  });
  return response;
};
