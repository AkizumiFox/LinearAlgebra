letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
lower_letters = "abcdefghijklmnopqrstuvwxyz"
greek_vectors = ["alpha","beta","gamma","delta","epsilon","zeta","eta","theta","iota","kappa","lambda","mu","nu","xi","pi","rho","sigma","tau","upsilon","phi","chi","psi","omega","varepsilon","vartheta","varpi","varrho","varsigma","varphi"]
greek_matrices = ["Gamma","Delta","Theta","Lambda","Xi","Pi","Sigma","Upsilon","Phi","Psi","Omega"]

def gen_defs():
    print("% --- 1. Latin Vectors (\va ... \vz) ---")
    for l in lower_letters:
        print(f"\\gdef\\v{l}{{\\mathbf{{{l}}}}}")
    for l in letters:
        print(f"\\gdef\\v{l}{{\\mathbf{{{l}}}}}")
        
    print("\n% --- 2. Latin Matrices (\A ... \Z) ---")
    for l in letters:
        print(f"\\gdef\\{l}{{\\mathbf{{{l}}}}}")
        print(f"\\gdef\\m{l}{{\\mathbf{{{l}}}}}")
        
    print("\n% --- 3. Greek Vectors & Matrices ---")
    for g in greek_vectors:
        print(f"\\gdef\\v{g}{{\\boldsymbol{{\\{g}}}}}")
    for g in greek_matrices:
        print(f"\\gdef\\v{g}{{\\mathbf{{\\{g}}}}}")
        
    print("\n% --- 4. Random Variables ---")
    for l in lower_letters:
        print(f"\\gdef\\r{l}{{\\mathbf{{{l}}}}}")
    for l in letters:
        print(f"\\gdef\\r{l}{{\\mathbf{{{l}}}}}")
        
    print("\n% --- 5. Cal and Blackboard Sets ---")
    for l in letters:
        print(f"\\gdef\\s{l}{{\\mathcal{{{l}}}}}")
        print(f"\\gdef\\n{l}{{\\mathbb{{{l}}}}}")

gen_defs()
