'use strict';
const { keccak256, ecsign } = require('ethereumjs-util');

//rootSigner私钥
// 该私钥钱包地址 0xC99F1314b093fB08514F2Fb8b213A2C4a537Fdf7
let privateKey = Buffer.from("4e79dfe8f508c45e08bdea94d8415762002befa0ee5add070dbe037fd2624936", "hex");

//高位补齐数据宽度
function pad(str, len){
    if(str.length >= len){
        return str;
    }
    for(let i = str.length; i < len; i++){
        str = "0" + str;
    }
    return str;
}

//TODO 当前的区块号，用于判断签名有效期，签名1日内有效
let blockNumber = 1;
blockNumber = blockNumber.toString(16);
blockNumber = pad(blockNumber, 64);

//TODO 用户和邀请人地址，注意无 0x 前缀
let user = "4B20993Bc481177ec7E8f571ceCaE8A9e22C02db";
let invitation = "78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB";

//拼接数据
let data = user + invitation + blockNumber;

//将数据以16进制的方式读取
let msg_data = Buffer.from(data, "hex");
let hash = keccak256(msg_data).toString('hex');

//椭圆曲线签名
let hash_buf = Buffer.alloc(32, hash, "hex");
let sig = ecsign(hash_buf, privateKey);

console.log("签名结果R: ", `0x${sig.r.toString('hex')}`, " S:", `0x${sig.s.toString('hex')}`, "V: ", sig.v);
