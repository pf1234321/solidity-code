const pinataSDK = require('@pinata/sdk');
const fs = require('fs');
const readline = require('readline');

// 配置 Pinata
const pinataApiKey = '1863380750ed25f5804f';
const pinataSecretApiKey = '45b0f2f5533721db15e74802b50dde489951842dee38fa0f611ddabcfd16d70a';
const pinata = pinataSDK(pinataApiKey, pinataSecretApiKey);

// 创建读取用户输入的接口
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// 上传文件到 Pinata
async function uploadToPinata(filePath) {
  try {
    const readableStream = fs.createReadStream(filePath);
    const result = await pinata.pinFileToIPFS(readableStream);
    const cid = result.IpfsHash;
    console.log(`✅ 文件已上传到 IPFS，CID: ${cid}`);
    console.log(`🔗 访问链接: https://gateway.pinata.cloud/ipfs/${cid}`);
    return cid;
  } catch (error) {
    console.error("上传失败:", error);
    throw error;
  }
}

// 上传元数据到 Pinata
async function uploadMetadataToPinata(metadata) {
  try {
    const result = await pinata.pinJSONToIPFS(metadata);
    const cid = result.IpfsHash;
    console.log(`\n✅ 元数据已上传到 IPFS，CID: ${cid}`);
    console.log(`🔗 元数据访问链接: https://gateway.pinata.cloud/ipfs/${cid}`);
    console.log(`🔗 OpenSea 兼容链接: ipfs://${cid}`);
    return cid;
  } catch (error) {
    console.error("创建或上传元数据失败:", error);
    throw error;
  }
}

// 主函数
async function main() {
  try {
    rl.question("请输入要上传的图片文件路径: ", async (imagePath) => {
      if (!fs.existsSync(imagePath)) {
        console.error("❌ 文件不存在，请检查路径");
        rl.close();
        return;
      }

      // 上传图片
      const imageCID = await uploadToPinata(imagePath);

      // 获取元数据信息
      rl.question("\n请输入 NFT 名称: ", (name) => {
        rl.question("请输入 NFT 描述: ", async (description) => {
          // 生成示例属性
          const attributes = [
            { trait_type: "Creator", value: "IPFS Upload Tool" },
            { trait_type: "Type", value: "Image" },
            { trait_type: "Upload Date", value: new Date().toISOString() }
          ];

          // 创建并上传元数据
          const metadata = {
            name,
            description,
            image: `ipfs://${imageCID}`,
            attributes
          };

          await uploadMetadataToPinata(metadata);
          rl.close();
        });
      });
    });
  } catch (error) {
    console.error("发生错误:", error);
    rl.close();
  }
}

main();
