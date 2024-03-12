const pinataSDK = require("@pinata/sdk");
require("dotenv").config();

const pinata = new pinataSDK({ pinataJWTKey: process.env.JWT_KEY });

async function createMetadata() {
  const json = {
    jobTitle: "Senior Software Engineer",
    company: "K3N",
    location: "San Francisco, CA",
    employmentType: "Full-time",
    remoteOption: true,
    description:
      "We're seeking a Senior Software Engineer to design, develop, and maintain our flagship product. You'll work in a fast-paced, agile environment to build scalable and reliable solutions.",
    responsibilities: [
      "Collaborate with cross-functional teams to define and implement new features",
      "Design and architect robust and performant software systems",
      "Write clean, well-tested, and maintainable code in Python",
      "Troubleshoot and resolve complex technical issues",
      "Mentor junior developers and contribute to code reviews",
    ],
    requirements: {
      mustHaves: [
        "5+ years of experience in software development",
        "Expertise in Python and object-oriented programming",
        "Experience with cloud-based technologies (AWS preferred)",
        "Strong problem-solving and debugging skills",
      ],
      niceToHaves: [
        "Experience with React or other frontend JavaScript frameworks",
        "Familiarity with distributed systems concepts",
      ],
    },
    compensation: {
      salaryRange: {
        min: 120000,
        max: 150000,
        currency: "USD",
      },
      benefits: [
        "Comprehensive medical, dental, and vision insurance",
        "401(k) with company match",
        "Generous paid time off and flexible work arrangements",
        "Professional development opportunities",
      ],
    },
    applyUrl: "https://www.k3n.com/careers/senior-software-engineer",
  };

  const job = {
    jobID: "1",
    image: "https://api.pudgypenguins.io/lil/image/5380",
    description:
      "Senior Software Engineer to design, develop, and maintain for flagship product",
    name: "Jane Doe - KOL",
    linkTwitter: "https://twitter.com/home",
    amountEarned: {
      value: 3500,
      currency: "USD",
    },
    certifications: [
      {
        name: "React Fundamentals",
        issuer: "Udemy",
        issueDate: "2023-10-01",
      },
    ],
  };

  const res = await pinata.pinJSONToIPFS(job);
  console.log("res:", res);
}

createMetadata();
