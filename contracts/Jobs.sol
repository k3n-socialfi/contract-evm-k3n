// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;
import './interfaces/IJobs.sol';
import './abstract/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Jobs is IJobs, ERC721, Ownable, ReentrancyGuard{

    // metadata for soul bound token
    string public baseTokenURI;

    uint256 jobId;

    uint256 tokenIdCounter;

    IERC20 rewardToken;

    mapping ( address => KolsInfo ) public kolsInfo;

    mapping ( uint256 => JobInfo ) public jobInfo;


    mapping ( address => mapping (uint256 => bool)) applicants;

    mapping ( address => mapping (uint256 => bool)) invitationKols;

    modifier onlyAuthorized(uint256 _jobId) {
        require(msg.sender == jobInfo[_jobId].creator || msg.sender == jobInfo[_jobId].kol, "Jobs: Only creator or KOL");
        _;
    }

    modifier mustNotStarted(uint256 _jobId) {
        require(jobInfo[_jobId].isStarted == false, "Jobs: Job has been started");
        _;
    }

    modifier mustNotCompleted(uint256 _jobId) {
        require(jobInfo[_jobId].isCompleted == false, "Jobs: Job has been completed");
        _;
    }

    modifier existsJobs(uint256 _jobId){
        require(jobInfo[_jobId].creator != address(0), "Jobs: Job does not exists");
        _;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _rewardToken
    ) ERC721 (_tokenName, _tokenSymbol) Ownable() {
        rewardToken = IERC20(_rewardToken);
    }

    // User create the new profile
    function createProfile(uint256 price) external {
        address signer = msg.sender;
        require (kolsInfo[signer].kolAddress == address(0), "Jobs: Profile already exists");
        KolsInfo memory kol;
        kol.kolAddress = signer;
        kol.price = price;
        kolsInfo[signer] = kol; 

        emit CreateProfile(signer, price);
    }

    // Kols update the profile
    function updateProfile(uint256 price) external {
        address signer = msg.sender;
        require (kolsInfo[signer].kolAddress == signer, "Jobs: Must be the owner of the profile");
        kolsInfo[signer].price = price;
    }

    // Create the new job
    function createJobs(uint256 budget, uint256 reward, string calldata detail) external nonReentrant {
        require(budget > 0 && reward > 0 && (budget + reward) <= rewardToken.balanceOf(msg.sender), "Jobs: Invalid number" );
        require(jobInfo[jobId + 1].creator == address(0), "Jobs: Job already exist");

        JobInfo memory job;

        jobId += 1;
        job.id = jobId;
        job.creator = msg.sender;
        job.budget = budget;
        job.reward = reward;
        job.detail = detail;
        jobInfo[jobId] = job;

        // Lock token reward and budget
        rewardToken.transferFrom(msg.sender, address(this), budget + reward);

        emit CreateJob(msg.sender, budget, reward, jobId);
    }

    // Creator update job
    function updateJobs(uint256 _jobId, string calldata detail) external nonReentrant {
        require(jobInfo[_jobId].creator == msg.sender, "Jobs: Must be the creator");

        jobInfo[_jobId].detail = detail;
    }

    // KOLS apply for the job
    function applyJobs(uint256 _jobId) mustNotStarted(_jobId) external returns(bool) {
        address signer = msg.sender;
        require(signer == kolsInfo[signer].kolAddress, "Jobs: You must be KOL");
        require(jobInfo[_jobId].creator != address(0), "Jobs: Job does not exist");

        applicants[signer][_jobId] = true;
        kolsInfo[signer].listAppliedJobs.push(_jobId);
        jobInfo[_jobId].listApplicants.push(signer);
        emit JobApplied(signer, _jobId);
        return true;
    }

    // Creator start the jobs 
    function startJobs(uint256 _jobId, address kolAddress) mustNotStarted(_jobId) external returns(bool) {
        require (jobInfo[_jobId].creator == msg.sender, "Jobs: Must be the creator" );
        require (applicants[kolAddress][_jobId], "Job: The applicant doesn't apply for a job");
        jobInfo[_jobId].isStarted = true;
        jobInfo[_jobId].kol = kolAddress;
        kolsInfo[kolAddress].jobsIds.push(_jobId);
        emit StartJob(_jobId, kolAddress);
        return true;

    }

    // Creator invite Kols for the job
    function inviteKol(uint256 _jobId, address kolAddress) existsJobs(_jobId) mustNotStarted(_jobId) external returns(bool) {
        address signer = msg.sender;
        require(signer== jobInfo[_jobId].creator, "Jobs: Only creator can invite kol");

        invitationKols[kolAddress][_jobId] = true;
        kolsInfo[kolAddress].listInvitationJobs.push(_jobId);
        jobInfo[_jobId].listInvitationKols.push(kolAddress);
        kolsInfo[kolAddress].listInvitationJobs.push(_jobId);

        emit InviteKol(_jobId, kolAddress);
        return true;


    }

    // Kols accept the invitation
    function acceptJobs(uint256 _jobId) mustNotStarted(_jobId) external returns(bool){
        address signer = msg.sender;
        require(invitationKols[signer][_jobId] == true, "Job: Signer not invited to the job");

        jobInfo[_jobId].isStarted = true;
        jobInfo[_jobId].kol = signer;
        kolsInfo[signer].jobsIds.push(_jobId);

        emit StartJob(_jobId, signer);
        return true;

    }

    // Kols and creator cancel the agreement
    function cancelJobs(uint256 _jobId) mustNotCompleted(_jobId) onlyAuthorized(_jobId) external returns(bool){
        address signer = msg.sender;
        JobInfo memory job = jobInfo[_jobId];
        require(job.isStarted == true, "Jobs: Job is not started");

        if (signer == job.creator) {
            job.cancelApproval[0] = true;
        } else if (signer== job.kol) {
            job.cancelApproval[1] = true;
        }

        if (job.cancelApproval[0] && job.cancelApproval[1]) {
            jobInfo[_jobId].isStarted = false;
            jobInfo[_jobId].kol = address(0);

        }
        emit CancelJob(_jobId);
        return true;
    }

    // Kols and creator complete the job
    function completeJobs(uint256 _jobId) mustNotCompleted(_jobId) onlyAuthorized(_jobId) external nonReentrant returns(bool){
        address signer = msg.sender;
        JobInfo memory job = jobInfo[_jobId];
        require(job.isStarted == true, "Jobs: Job is not started");

        if (signer == job.creator) {
            jobInfo[_jobId].completedApproval[0] = true;
        } else if (signer == job.kol) {
            jobInfo[_jobId].completedApproval[1] = true;
        }

        if (jobInfo[_jobId].completedApproval[0] && jobInfo[_jobId].completedApproval[1]) {
            jobInfo[_jobId].isCompleted = true;


            kolsInfo[job.kol].creditPoints += 1;
            
            // Mint soul bound token
            tokenIdCounter += 1;
            kolsInfo[job.kol].tokenIds.push(tokenIdCounter);
            _safeMint(job.kol, tokenIdCounter);

            rewardToken.transfer(msg.sender, job.reward);
        }

        emit CompletedJob(_jobId, job.kol);
        return true;
    }

    // Creator delete the job before work is started
    function deleteJobs(uint256 _jobId) mustNotStarted(_jobId) external {
        require(jobInfo[_jobId].creator == msg.sender, "Jobs: Must be the creator");
        JobInfo memory job = jobInfo[_jobId];

        rewardToken.transfer(msg.sender, job.reward + job.budget );
        delete jobInfo[_jobId];
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getKolInfo(address kol) public view returns(KolsInfo memory info){
        info = kolsInfo[kol];
    }

    function getJobInfo(uint256 _jobId) public view returns(JobInfo memory info){
        info = jobInfo[_jobId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        require(from == address(0), "Jobs: Token not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return bytes(baseTokenURI).length > 0 ? baseTokenURI : " ";
    }
}
