const { assert, expect } = require('chai')
const { web3Utils } = require('web3-utils')
const { solidity } = require('ethereum-waffle')

const HashUpAds = artifacts.require("HashUpAd")
const HashUp = artifacts.require("HashUp")

require('chai').use(require('chai-as-promised')).should()
require('chai').use(solidity)

function convertTokens(n) {
    //Hash has 18 decimals.
    return web3.utils.toWei(n, 'ether')
}

contract('HashUpAds', (accounts) => {

    let hashUp, hashUpAds
    let deployer = accounts[0]
    let user = accounts[1] //1000# after transfers at the begining
    let bidBuyer = accounts[2] //1000# after transfers at the begining
    let seller = accounts[3] //0# on start, 50# after sell to bidBuyer

    const days = 5
    const defaultAdUrl = 'test url'
    const defaultAdImageUrl = 'test image url'
    const defaultAskPrice = 10**18;

    before(async () => {
        hashUp = await HashUp.new()
        hashUpAds = await HashUpAds.new(
            hashUp.address, 
            days, 
            0, 
            defaultAdUrl, 
            defaultAdImageUrl
        )
        
    })

    describe('Transferring tokens to contract', async () => {
        it('transfers correctly', async () => {
            await hashUp.transfer(user, convertTokens('1000'), {from: deployer})
            const userBalance = await hashUp.balanceOf(user)
            assert.equal(userBalance.toString(), convertTokens('1000'), 'User doesnt get hash')

            await hashUp.transfer(bidBuyer, convertTokens('1000'), {from: deployer})
            const bidBuyerBalance = await hashUp.balanceOf(bidBuyer)
            assert.equal(bidBuyerBalance.toString(), convertTokens('1000'))
        })
    })

    describe('Checking default values after creation contract defined in constructor', async () => {
        for(let i = 0; i < days; i++) {
            it('Gives default values after creation', async () => {
                const values = await hashUpAds.getAdDay(i)
                assert.equal(values[0], deployer, 'dayOwner[day]')
                assert.equal(values[1], defaultAdUrl, 'urlForAd[day]')
                assert.equal(values[2], defaultAdImageUrl, 'imageUrlForAd[day]')
            })
        }
    })

    describe('Change owner of the day', async () => {
        it('Gives current owner', async () => {
            const owner = await hashUpAds.getOwnerOfDay(0)
            assert.equal(owner, deployer, `Owner isn't a deployer`)
        })

        it('Change owner', async () => {
            const makeNewOwner = await hashUpAds.setOwnerOfDay(0, user, {from: deployer})
            const testOwner = await hashUpAds.getOwnerOfDay(0)
            assert.equal(user, testOwner, 'Owners should be equal')

            const backOwnerToDeployer = await hashUpAds.setOwnerOfDay(0, deployer, {from: user})
        })

        it('Not allowed to change owner if account is not an owner', async () => {
            //VM Exception while processing transaction: revert
            await expect(hashUpAds.setOwnerOfDay(0, user, {from: user})).to.be.reverted;
        })
    })

    describe('Testing setAdForDay', async () => {
        it('Get day Data', async () => {
            const values = await hashUpAds.getAdDay(0)
            assert.equal(values[0], deployer, 'dayOwner[day]')
            assert.equal(values[1], defaultAdUrl, 'urlForAd[day]')
            assert.equal(values[2], defaultAdImageUrl, 'imageUrlForAd[day]')
        })

        it('Change data if sender is an owner', async () => {
            const newUrl = 'new url'
            const newImageUrl = 'new image url'

            const setingNewAdData = await hashUpAds.setAdForDay(0, newUrl, newImageUrl, {from: deployer})
                    
            const values = await hashUpAds.getAdDay(0)
            assert.equal(values[0], deployer, 'dayOwner[day]')
            assert.equal(values[1], newUrl, 'urlForAd[day]')
            assert.equal(values[2], newImageUrl, 'imageUrlForAd[day]')
        })

        it('Revert when not owner want to change some data', async () => {
            await expect(hashUpAds.setAdForDay(0, '', '', {from: user})).to.be.reverted;
        })
    })

    describe('Testing dex of day index', async () => {
        it('Get ask price of ad, should return default price', async () => {
            const price = (await hashUpAds.getAdDay(0))[3]
            assert.equal(price, defaultAskPrice, "Default ask price doesn't equal defautl")
        })

        it('Set ask price of ad from 10# to 100#', async () => {
            const settingAskPrice = await hashUpAds.askAd(0, convertTokens('100'), {from: deployer})

            const newPrice = (await hashUpAds.getAdDay(0))[3]
            assert.equal(newPrice.toString(), convertTokens('100'), "New price not equal 100#")
        })

        it('Buy from Ask', async () => {
            const givingApprove = await hashUp.approve(hashUpAds.address, convertTokens('100'), {from: user})

            const oldOwner = (await hashUpAds.getAdDay(0))[0]
            const oldOwnerBalance = await hashUp.balanceOf(deployer)
            const oldBuyerBalance = await hashUp.balanceOf(user)

            assert.equal(oldBuyerBalance, convertTokens('1000'), "check ")
            assert.equal(deployer, oldOwner, "Check old owner")

            const buying = await hashUpAds.buyFromAsk(0, {from: user})
            const newDayOwner = (await hashUpAds.getAdDay(0))[0]
            assert.equal(user, newDayOwner, "Change day owner to user")

            const balanceOfUser = await hashUp.balanceOf(user)
            assert.equal(balanceOfUser, convertTokens('900'), "Transfer # to seller")

            const backOwnerToDeployer = await hashUpAds.setOwnerOfDay(0, deployer, {from: user})
        })

        it('Bid ad and sell it to user', async () => {
            const goOwnerToSeller = await hashUpAds.setOwnerOfDay(0, seller, {from: deployer})

            const givingApprove = await hashUp.approve(hashUpAds.address, convertTokens('50'), {from: bidBuyer})
            const setBid = await hashUpAds.bidAd(0, convertTokens('50'), {from: bidBuyer})
            const sellToBid = await hashUpAds.sellToBid(0, {from: seller})

            const balanceOfSeller = await hashUp.balanceOf(seller)
            assert.equal(balanceOfSeller.toString(), convertTokens('50'), "Balance after sell not correct")

            const buyerNewBalance = await hashUp.balanceOf(bidBuyer)
            assert.equal(buyerNewBalance, convertTokens('950'), "Balance after sell not correct")
        })
    })
})