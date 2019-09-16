#!groovy
// - Harden Jenkins - since we skipping wizard for container build
// - this is just for testing - dont mind the pwd/user

import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.*
import hudson.security.csrf.DefaultCrumbIssuer

//set default admin user
def instance = Jenkins.getInstance()
println "--> creating local user 'admin'"

//disable CLI remoting mode
instance.getDescriptor("jenkins.CLI").get().setEnabled(false)

//set CSRF protection
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

//set agent/ master subsystem
instance.injector.getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false);

// Disable old Non-Encrypted protocols
HashSet<String> newProtocols = new HashSet<>(instance.getAgentProtocols());
newProtocols.removeAll(Arrays.asList(
        "JNLP3-connect", "JNLP2-connect", "JNLP-connect", "CLI-connect"
));
instance.setAgentProtocols(newProtocols);

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin','admin1')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

def strategyMatrix = new GlobalMatrixAuthorizationStrategy()
strategyMatrix.add(Jenkins.ADMINISTER, "admin")
instance.setAuthorizationStrategy(strategyMatrix)

instance.save()